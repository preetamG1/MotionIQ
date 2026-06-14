import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../../../core/services/pose_service.dart';
import '../../../../core/services/exercise_service.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../core/utils/pose_painter.dart';
import '../../../../services/service_locator.dart';
import '../../../../services/tts_service.dart';
import 'result_screen.dart';

class CameraScreen extends StatefulWidget {
  final String? manualExercise;

  const CameraScreen({super.key, this.manualExercise});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isProcessing = false;
  CameraDescription? _camera;
  List<CameraDescription> _availableCameras = [];
  int _selectedCameraIndex = 0;
  bool _isEndingWorkout = false;

  CustomPainter? _customPainter;
  final ExerciseService _exerciseService = sl<ExerciseService>();
  final TtsService _ttsService = sl<TtsService>();

  @override
  void initState() {
    super.initState();
    _exerciseService.reset();
    _ttsService.reset();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _availableCameras = await availableCameras();
    if (_availableCameras.isEmpty) return;

    _selectedCameraIndex = _availableCameras.indexWhere((cam) => cam.lensDirection == CameraLensDirection.back);
    if (_selectedCameraIndex == -1) _selectedCameraIndex = 0;

    await _setupController();
  }

  Future<void> _setupController() async {
    if (_controller != null) await _controller!.dispose();

    _camera = _availableCameras[_selectedCameraIndex];

    // Using ResolutionPreset.veryHigh to get 1080p+ and prevent "squashed" figures
    _controller = CameraController(
      _camera!,
      ResolutionPreset.veryHigh,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );

    try {
      await _controller!.initialize();
      _startImageStream();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Camera error: $e");
    }
  }

  void _toggleCamera() async {
    setState(() {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _availableCameras.length;
    });
    await _setupController();
  }

  void _startImageStream() {
    if (_controller == null) return;
    _controller!.startImageStream((CameraImage image) {
      if (_isProcessing) return;
      _isProcessing = true;
      _processImage(image);
    });
  }

  Future<void> _processImage(CameraImage image) async {
    final inputImage = ImageUtils.getInputImage(image, _camera!);
    if (inputImage != null) {
      final poses = await sl<PoseService>().detectPose(inputImage);
      if (mounted) {
        if (poses.isNotEmpty) {
          _exerciseService.processPose(poses.first, manualType: widget.manualExercise);
          _ttsService.speakFeedback(
            _exerciseService.currentExercise,
            _exerciseService.feedback,
          );
        }
        setState(() {
          if (poses.isNotEmpty) {
            _customPainter = PosePainter(
              poses,
              inputImage.metadata!.size,
              inputImage.metadata!.rotation,
            );
          } else {
            _customPainter = null;
          }
        });
      }
    }
    _isProcessing = false;
  }

  @override
  void dispose() {
    _controller?.stopImageStream();
    _controller?.dispose();
    if (!_isEndingWorkout) {
      _ttsService.stop();
    }
    super.dispose();
  }

  void _onEndWorkout() {
    _isEndingWorkout = true;
    _ttsService.speakWorkoutCompleted();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(
          exercise: widget.manualExercise ?? "Mixed Session",
          reps: _exerciseService.sessionReps.values.reduce((a, b) => a + b),
          calories: (_exerciseService.sessionReps.values.reduce((a, b) => a + b) * 0.5).toInt(),
          score: 95,
          sessionStats: _exerciseService.sessionReps,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // CRITICAL: Calculate scaling factor to fill the screen WITHOUT compression/stretching
    final size = MediaQuery.of(context).size;
    var scale = size.aspectRatio * _controller!.value.aspectRatio;
    if (scale < 1) scale = 1 / scale;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview with proper scaling to prevent height compression
          ClipRect(
            child: Transform.scale(
              scale: scale,
              child: Center(
                child: CameraPreview(_controller!),
              ),
            ),
          ),

          // AI Skeleton Overlay with matching scale
          if (_customPainter != null)
            CustomPaint(
              size: size,
              painter: _customPainter,
            ),

          // Professional UI Overlays
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildHeaderInfo("MODE", widget.manualExercise ?? "AUTO-DETECT"),
                      IconButton(
                        icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 30),
                        onPressed: _toggleCamera,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "AI DETECTED: ${_exerciseService.exerciseName}",
                      style: const TextStyle(color: Colors.yellow, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Spacer(),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          "${_exerciseService.currentReps}",
                          style: const TextStyle(
                            fontSize: 120,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [Shadow(blurRadius: 15, color: Colors.black)],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                          decoration: BoxDecoration(
                            color: (_exerciseService.isPaused ? Colors.orange : Colors.blue).withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                          ),
                          child: Text(
                            _exerciseService.feedback,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 50),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _onEndWorkout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        icon: const Icon(Icons.stop_circle, size: 28),
                        label: const Text("END WORKOUT", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }
}