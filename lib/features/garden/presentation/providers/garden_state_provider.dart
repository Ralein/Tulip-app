import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DayTime { morning, afternoon, evening, night }
enum GardenWeather { sunny, rainy, starry, windy }

class GardenState {
  final DayTime time;
  final GardenWeather weather;

  const GardenState({
    required this.time,
    required this.weather,
  });

  GardenState copyWith({
    DayTime? time,
    GardenWeather? weather,
  }) {
    return GardenState(
      time: time ?? this.time,
      weather: weather ?? this.weather,
    );
  }
}

class GardenStateNotifier extends StateNotifier<GardenState> {
  GardenStateNotifier()
      : super(const GardenState(
          time: DayTime.afternoon,
          weather: GardenWeather.sunny,
        ));

  void updateTime(DayTime newTime) {
    state = state.copyWith(time: newTime);
  }

  void updateWeather(GardenWeather newWeather) {
    state = state.copyWith(weather: newWeather);
  }
}

final gardenStateProvider = StateNotifierProvider<GardenStateNotifier, GardenState>((ref) {
  return GardenStateNotifier();
});
