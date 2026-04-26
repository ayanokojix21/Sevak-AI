/// Base class for all application failures.
/// Every error in the system is mapped to a Failure subclass,
/// ensuring no raw exceptions ever reach the UI.
abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => '$runtimeType: $message';
}


class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection. Please check your network.']);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message = 'The request timed out. Please try again.']);
}


class AIFailure extends Failure {
  const AIFailure([super.message = 'AI processing failed. Please try again.']);
}

class AIRateLimitFailure extends Failure {
  const AIRateLimitFailure(
    [super.message = 'AI service is busy. Please wait a moment and try again.']);
}

class AIInvalidResponseFailure extends Failure {
  const AIInvalidResponseFailure(
    [super.message = 'AI returned an unexpected response. The need was saved for manual review.']);
}


class ImageUploadFailure extends Failure {
  const ImageUploadFailure(
    [super.message = 'Image upload failed. The need will be saved without a photo.']);
}

class ImageCompressionFailure extends Failure {
  const ImageCompressionFailure([super.message = 'Could not process the image. Please try again.']);
}


class LocationFailure extends Failure {
  const LocationFailure([super.message = 'Could not get your location. Please enable GPS.']);
}

class GeocodingFailure extends Failure {
  const GeocodingFailure(
    [super.message = 'Could not find this location on the map. Your GPS location will be used instead.']);
}

class LocationPermissionFailure extends Failure {
  const LocationPermissionFailure(
    [super.message = 'Location permission was denied. Please allow location access in Settings.']);
}


class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed. Please try again.']);
}

class UserNotFoundFailure extends Failure {
  const UserNotFoundFailure([super.message = 'No account found. Please sign up first.']);
}

class WrongPasswordFailure extends Failure {
  const WrongPasswordFailure([super.message = 'Incorrect password. Please try again.']);
}

class EmailAlreadyInUseFailure extends Failure {
  const EmailAlreadyInUseFailure([super.message = 'This email is already registered.']);
}


class DatabaseFailure extends Failure {
  const DatabaseFailure([super.message = 'Database error. Your data has been saved locally and will sync when online.']);
}


class NoVolunteersAvailableFailure extends Failure {
  const NoVolunteersAvailableFailure(
    [super.message = 'No volunteers are available nearby. Please try again later.']);
}


class GroqFailure extends Failure {
  const GroqFailure([super.message = 'Groq AI service is unavailable. Falling back to Gemini.']);
}

class AllProvidersFailure extends Failure {
  const AllProvidersFailure([super.message = 'All AI providers are currently unavailable. Please try again later.']);
}
