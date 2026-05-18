import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fin_track/features/travel_planner/data/datasources/travel_functions_datasource.dart';
import 'package:fin_track/features/travel_planner/data/datasources/trip_plan_remote_datasource.dart';
import 'package:fin_track/features/travel_planner/data/repositories/travel_planner_repository_impl.dart';
import 'package:fin_track/features/travel_planner/domain/entities/destination_entity.dart';
import 'package:fin_track/features/travel_planner/domain/entities/place_details_entity.dart';
import 'package:fin_track/features/travel_planner/domain/entities/travel_place_entity.dart';
import 'package:fin_track/features/travel_planner/domain/entities/trip_plan_entity.dart';
import 'package:fin_track/features/travel_planner/domain/repositories/travel_planner_repository.dart';
import 'package:fin_track/features/travel_planner/domain/usecases/save_trip_plan_usecase.dart';
import 'package:fin_track/features/travel_planner/domain/usecases/search_destination_usecase.dart';
import 'package:fin_track/features/travel_planner/domain/usecases/search_hotels_usecase.dart';
import 'package:fin_track/features/travel_planner/domain/usecases/search_restaurants_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final travelFunctionsDataSourceProvider = Provider((ref) {
  return TravelFunctionsDataSource(FirebaseFunctions.instance);
});

final tripPlanRemoteDataSourceProvider = Provider((ref) {
  return TripPlanRemoteDataSource(FirebaseFirestore.instance);
});

final travelPlannerRepositoryProvider = Provider<TravelPlannerRepository>((ref) {
  return TravelPlannerRepositoryImpl(
    functionsDataSource: ref.watch(travelFunctionsDataSourceProvider),
    remoteDataSource: ref.watch(tripPlanRemoteDataSourceProvider),
  );
});

final searchDestinationUseCaseProvider = Provider((ref) {
  return SearchDestinationUseCase(ref.watch(travelPlannerRepositoryProvider));
});

final searchHotelsUseCaseProvider = Provider((ref) {
  return SearchHotelsUseCase(ref.watch(travelPlannerRepositoryProvider));
});

final searchRestaurantsUseCaseProvider = Provider((ref) {
  return SearchRestaurantsUseCase(ref.watch(travelPlannerRepositoryProvider));
});

final saveTripPlanUseCaseProvider = Provider((ref) {
  return SaveTripPlanUseCase(ref.watch(travelPlannerRepositoryProvider));
});

class TravelPlannerState {
  final DestinationEntity? destination;
  final List<TravelPlaceEntity> hotels;
  final List<TravelPlaceEntity> restaurants;
  final TravelPlaceEntity? selectedHotel;
  final AsyncValue<void> action;

  const TravelPlannerState({
    this.destination,
    this.hotels = const [],
    this.restaurants = const [],
    this.selectedHotel,
    this.action = const AsyncValue.data(null),
  });

  String get summary {
    if (destination == null || selectedHotel == null) {
      return 'Pilih destinasi dan hotel untuk membuat plan.';
    }

    final topRestaurant =
        restaurants.isEmpty ? 'restoran terdekat' : restaurants.first.name;
    return '${selectedHotel!.name} direkomendasikan di ${destination!.name} '
        'karena rating kuat, jarak efisien, dan dekat dengan $topRestaurant.';
  }

  TravelPlannerState copyWith({
    DestinationEntity? destination,
    List<TravelPlaceEntity>? hotels,
    List<TravelPlaceEntity>? restaurants,
    TravelPlaceEntity? selectedHotel,
    AsyncValue<void>? action,
  }) {
    return TravelPlannerState(
      destination: destination ?? this.destination,
      hotels: hotels ?? this.hotels,
      restaurants: restaurants ?? this.restaurants,
      selectedHotel: selectedHotel ?? this.selectedHotel,
      action: action ?? this.action,
    );
  }
}

class TravelPlannerNotifier extends StateNotifier<TravelPlannerState> {
  final SearchDestinationUseCase _searchDestination;
  final SearchHotelsUseCase _searchHotels;
  final SearchRestaurantsUseCase _searchRestaurants;
  final SaveTripPlanUseCase _saveTripPlan;

  TravelPlannerNotifier({
    required SearchDestinationUseCase searchDestination,
    required SearchHotelsUseCase searchHotels,
    required SearchRestaurantsUseCase searchRestaurants,
    required SaveTripPlanUseCase saveTripPlan,
  })  : _searchDestination = searchDestination,
        _searchHotels = searchHotels,
        _searchRestaurants = searchRestaurants,
        _saveTripPlan = saveTripPlan,
        super(const TravelPlannerState());

  Future<void> search(String query) async {
    state = state.copyWith(action: const AsyncValue.loading());
    try {
      final destination = await _searchDestination(query);
      final hotels = await _searchHotels(destination);

      state = TravelPlannerState(
        destination: destination,
        hotels: hotels,
        restaurants: const [],
        selectedHotel: null,
      );
    } catch (error, stackTrace) {
      state = state.copyWith(action: AsyncValue.error(error, stackTrace));
    }
  }

  Future<void> selectHotel(TravelPlaceEntity hotel) async {
    state = state.copyWith(
      selectedHotel: hotel,
      restaurants: const [],
      action: const AsyncValue.loading(),
    );

    try {
      final restaurants = await _searchRestaurants(hotel);
      state = state.copyWith(
        restaurants: restaurants,
        action: const AsyncValue.data(null),
      );
    } catch (error, stackTrace) {
      state = state.copyWith(action: AsyncValue.error(error, stackTrace));
    }
  }

  Future<void> save() async {
    final destination = state.destination;
    final selectedHotel = state.selectedHotel;
    if (destination == null || selectedHotel == null) return;

    state = state.copyWith(action: const AsyncValue.loading());
    try {
      await _saveTripPlan(
        TripPlanEntity(
          id: '',
          destination: destination,
          selectedHotel: selectedHotel,
          restaurants: state.restaurants.take(3).toList(),
          summary: state.summary,
          createdAt: DateTime.now(),
        ),
      );
      state = state.copyWith(action: const AsyncValue.data(null));
    } catch (error, stackTrace) {
      state = state.copyWith(action: AsyncValue.error(error, stackTrace));
    }
  }
}

final travelPlannerProvider =
    StateNotifierProvider<TravelPlannerNotifier, TravelPlannerState>((ref) {
  return TravelPlannerNotifier(
    searchDestination: ref.watch(searchDestinationUseCaseProvider),
    searchHotels: ref.watch(searchHotelsUseCaseProvider),
    searchRestaurants: ref.watch(searchRestaurantsUseCaseProvider),
    saveTripPlan: ref.watch(saveTripPlanUseCaseProvider),
  );
});

/// Provider to fetch reviews + price level for a specific place.
/// Usage: ref.watch(placeDetailsProvider(placeId))
final placeDetailsProvider =
    FutureProvider.family<PlaceDetails, String>((ref, placeId) async {
  final dataSource = ref.watch(travelFunctionsDataSourceProvider);
  return dataSource.getPlaceDetails(placeId);
});
