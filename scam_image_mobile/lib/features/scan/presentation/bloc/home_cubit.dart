import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

// ── States ────────────────────────────────────────────────────────────────────

abstract class HomeState extends Equatable {
  const HomeState();
}

/// Initial / idle state.
class HomeInitial extends HomeState {
  const HomeInitial();
  @override
  List<Object?> get props => [];
}

/// System image picker is open / file is being read.
class HomeImagePickerLoading extends HomeState {
  const HomeImagePickerLoading();
  @override
  List<Object?> get props => [];
}

/// User selected a valid image file.
class HomeImageSelected extends HomeState {
  final String filePath;
  final int fileSizeBytes;

  const HomeImageSelected(this.filePath, this.fileSizeBytes);

  @override
  List<Object?> get props => [filePath, fileSizeBytes];
}

/// Gallery / camera permission was denied by the user.
class HomePermissionDenied extends HomeState {
  const HomePermissionDenied();
  @override
  List<Object?> get props => [];
}

/// An unexpected error occurred while picking the image.
class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object?> get props => [message];
}

// ── Cubit ─────────────────────────────────────────────────────────────────────

/// Manages the state for [HomeScreen] — specifically the image-picker flow.
class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(const HomeInitial());

  /// Opens the system gallery picker and emits the appropriate state.
  Future<void> pickImage() async {
    emit(const HomeImagePickerLoading());

    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85, // compress to ~85% quality
        maxWidth: 2048,
        maxHeight: 2048,
      );

      if (file == null) {
        // User cancelled without selecting a file.
        emit(const HomeInitial());
        return;
      }

      final fileSize = await File(file.path).length();
      emit(HomeImageSelected(file.path, fileSize));
    } on PlatformException catch (e) {
      if (e.code == 'photo_access_denied' ||
          e.code == 'camera_access_denied') {
        emit(const HomePermissionDenied());
      } else {
        emit(HomeError(e.message ?? 'เกิดข้อผิดพลาด'));
      }
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }
}
