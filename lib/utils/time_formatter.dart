String formatReadingTime(int totalSeconds) {
  if (totalSeconds <= 0) return '0 min';
  
  final duration = Duration(seconds: totalSeconds);
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);

  if (hours > 0) {
    return '${hours}h ${minutes}m';
  } else if (minutes > 0) {
    // Si hay minutos, ignoramos los segundos para un look más limpio en stats
    return '${minutes} min';
  } else {
    return '${seconds} seg';
  }
}