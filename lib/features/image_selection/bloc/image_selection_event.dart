part of 'image_selection_bloc.dart';

@immutable
sealed class ImageSelectionEvent {}

final class PickImageEvent extends ImageSelectionEvent {
  final ImageSource source;
  PickImageEvent(this.source);
}

final class ClearImageEvent extends ImageSelectionEvent {}
