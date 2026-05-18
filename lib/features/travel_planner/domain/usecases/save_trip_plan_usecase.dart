import 'package:fin_track/features/travel_planner/domain/entities/trip_plan_entity.dart';
import 'package:fin_track/features/travel_planner/domain/repositories/travel_planner_repository.dart';

class SaveTripPlanUseCase {
  final TravelPlannerRepository _repository;

  const SaveTripPlanUseCase(this._repository);

  Future<void> call(TripPlanEntity tripPlan) {
    return _repository.saveTripPlan(tripPlan);
  }
}
