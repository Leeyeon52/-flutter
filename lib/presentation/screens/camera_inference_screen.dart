import 'package:flutter/material.dart';
import 'package:ultralytics_yolo/yolo.dart';
import 'package:ultralytics_yolo/yolo_result.dart';
import 'package:ultralytics_yolo/yolo_view.dart';
import '/models/model_type.dart';
import '/models/slider_type.dart';
import '/services/model_manager.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // json 디코드용
import 'package:go_router/go_router.dart'; // context.push 사용을 위해 추가

const int _kAlpha80Percent = 204; // 0.8 * 255
const int _kAlpha50Percent = 127;
const int _kAlpha20Percent = 51;
const int _kAlpha60Percent = 153;
const int _kAlpha30Percent = 76;

int _captureIndex = 1;
DateTime? _lastCaptureDate;

class CameraInferenceScreen extends StatefulWidget {
  final String userId;
  final String baseUrl;

  const CameraInferenceScreen({
    Key? key,
    required this.userId,
    required this.baseUrl,
  }) : super(key: key);

  @override
  CameraInferenceScreenState createState() => CameraInferenceScreenState();
}

class CameraInferenceScreenState extends State<CameraInferenceScreen> {
  List<String> _classifications = [];
  int _detectionCount = 0;
  double _confidenceThreshold = 0.5;
  double _iouThreshold = 0.45;
  int _numItemsThreshold = 30;
  double _currentFps = 0.0;
  int _frameCount = 0;
  DateTime _lastFpsUpdate = DateTime.now();

  SliderType _activeSlider = SliderType.none;
  ModelType _selectedModel = ModelType.segment;
  bool _isModelLoading = false;
  String? _modelPath;
  String _loadingMessage = '';
  double _downloadProgress = 0.0;
  double _currentZoomLevel = 1.0;
  bool _isFrontCamera = false;

  final _yoloController = YOLOViewController();
  final _yoloViewKey = GlobalKey<YOLOViewState>();
  final bool _useController = true;

  late final ModelManager _modelManager;

  @override
  void initState() {
    super.initState();

    _modelManager = ModelManager(
      onDownloadProgress: (progress) {
        if (mounted) {
          setState(() {
            _downloadProgress = progress;
          });
        }
      },
      onStatusUpdate: (message) {
        if (mounted) {
          setState(() {
            _loadingMessage = message;
          });
        }
      },
    );

    _loadModelForPlatform();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_useController) {
        _yoloController.setThresholds(
          confidenceThreshold: _confidenceThreshold,
          iouThreshold: _iouThreshold,
          numItemsThreshold: _numItemsThreshold,
        );
      } else {
        _yoloViewKey.currentState?.setThresholds(
          confidenceThreshold: _confidenceThreshold,
          iouThreshold: _iouThreshold,
          numItemsThreshold: _numItemsThreshold,
        );
      }
    });
  }

  void _onDetectionResults(List<YOLOResult> results) {
    debugPrint('🟦 onDetectionResults called: ${results.length}개');
    if (!mounted) return;

    _frameCount++;
    final now = DateTime.now();
    final elapsed = now.difference(_lastFpsUpdate).inMilliseconds;
    if (elapsed >= 1000) {
      _currentFps = _frameCount * 1000 / elapsed;
      _frameCount = 0;
      _lastFpsUpdate = now;
      debugPrint('Calculated FPS: ${_currentFps.toStringAsFixed(1)}');
    }

    setState(() {
      _detectionCount = results.length;
      if (_selectedModel.task == YOLOTask.classify) {
        _classifications = results
            .take(3)
            .map((r) => r.confidence < 0.5
                ? "알 수 없음"
                : "${r.className} ${(r.confidence * 100).toStringAsFixed(1)}%")
            .toList();
      } else {
        _classifications = [];
      }
      debugPrint('_classifications: $_classifications');
    });
  }

  Future<void> _captureAndSendToServer() async {
    debugPrint('🟢 _captureAndSendToServer: Start');

    try {
      if (!_yoloController.isInitialized) {
        throw Exception('YOLO 컨트롤러가 초기화되지 않았습니다. 잠시 후 다시 시도해주세요.');
      }

      setState(() {
        _isModelLoading = true;
        _loadingMessage = '원본 이미지 캡처 중...';
      });

      final Uint8List? imageData = await _yoloController.captureFrame();
      if (imageData == null) {
        throw Exception('이미지 캡처에 실패했습니다. 다시 시도해주세요.');
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      if (_lastCaptureDate == null || _lastCaptureDate != today) {
        _captureIndex = 1;
        _lastCaptureDate = today;
      } else {
        _captureIndex += 1;
      }

      final formattedDate = "${now.year.toString().padLeft(4, '0')}"
          "${now.month.toString().padLeft(2, '0')}"
          "${now.day.toString().padLeft(2, '0')}"
          "${now.hour.toString().padLeft(2, '0')}"
          "${now.minute.toString().padLeft(2, '0')}"
          "${now.second.toString().padLeft(2, '0')}";

      final filename = "${widget.userId}_${formattedDate}_${_captureIndex}.png";

      final String serverUrl = '${widget.baseUrl}/api/upload_image';

      final request = http.MultipartRequest('POST', Uri.parse(serverUrl))
        ..fields['user_id'] = widget.userId
        ..fields['filename'] = filename;

      // 💡💡💡 수정: 이미지 파일을 보내는 필드 이름을 'file'로 변경합니다. 💡💡💡
      request.files.add(http.MultipartFile.fromBytes(
        'file', // 백엔드에서 'file' 필드 이름으로 파일을 받을 가능성이 있습니다.
        imageData,
        filename: filename,
      ));

      final response = await request.send();

      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        debugPrint('📤 $filename 업로드 성공! 서버 응답: $responseBody');

        final Map<String, dynamic> jsonResponse = json.decode(responseBody);

        final String? imageUrl = jsonResponse['image_url'];
        final dynamic inferenceData = jsonResponse['inference_data'];
        final String? message = jsonResponse['message'];

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('📷 $filename 업로드 완료: ${message ?? '성공'}')),
          );

          if (imageUrl != null && inferenceData != null) {
            context.push('/result', extra: {
              'imageUrl': imageUrl,
              'inferenceData': inferenceData,
              'userId': widget.userId,
              'baseUrl': widget.baseUrl,
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('서버 응답 오류: 필요한 데이터가 부족합니다.')),
            );
          }
        }
      } else {
        debugPrint('❌ 업로드 실패: Status Code ${response.statusCode}, 응답: $responseBody');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('업로드 실패: ${response.statusCode} - ${responseBody.length > 100 ? responseBody.substring(0, 100) + '...' : responseBody}')),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ 오류 발생: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: ${e.toString()}')),
        );
      }
    } finally {
      debugPrint('🟢 _captureAndSendToServer: 완료');
      if (mounted) {
        setState(() {
          _isModelLoading = false;
          _loadingMessage = '';
        });
      }
    }
  }

  Widget _buildCaptureButton() {
    return FloatingActionButton(
      onPressed: _captureAndSendToServer,
      backgroundColor: Colors.orange,
      child: const Icon(Icons.camera_alt_outlined, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;

    return Scaffold(
      body: Stack(
        children: [
          if (_modelPath != null && !_isModelLoading)
            YOLOView(
              key: _useController
                  ? const ValueKey('yolo_view_static')
                  : _yoloViewKey,
              controller: _useController ? _yoloController : null,
              modelPath: _modelPath!,
              task: _selectedModel.task,
              onResult: _onDetectionResults,
              onPerformanceMetrics: (metrics) {
                if (mounted) {
                  setState(() {
                    _currentFps = metrics.fps;
                  });
                }
              },
              onZoomChanged: (zoomLevel) {
                if (mounted) {
                  setState(() {
                    _currentZoomLevel = zoomLevel;
                  });
                }
              },
            )
          else if (_isModelLoading)
            IgnorePointer(
              child: Container(
                color: Colors.black.withAlpha(_kAlpha80Percent),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/logo.png',
                        width: 120,
                        height: 120,
                        color: Colors.white.withAlpha(_kAlpha80Percent),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        _loadingMessage,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      if (_downloadProgress > 0)
                        Column(
                          children: [
                            SizedBox(
                              width: 200,
                              child: LinearProgressIndicator(
                                value: _downloadProgress,
                                backgroundColor:
                                    Colors.white.withAlpha(_kAlpha20Percent),
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                                minHeight: 4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${(_downloadProgress * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            )
          else
            const Center(
              child: Text(
                '모델이 로드되지 않았습니다',
                style: TextStyle(color: Colors.white),
              ),
            ),

          if (_classifications.isNotEmpty)
            Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _classifications
                    .map(
                      (txt) => Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha((0.7 * 255).toInt()),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin:
                            const EdgeInsets.symmetric(vertical: 4, horizontal: 24),
                        padding:
                            const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                        child: Text(
                          txt,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),

          Positioned(
            top: MediaQuery.of(context).padding.top + (isLandscape ? 8 : 16),
            left: isLandscape ? 8 : 16,
            right: isLandscape ? 8 : 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: isLandscape ? 8 : 12),
                IgnorePointer(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'SEGMENTATION: $_detectionCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'FPS: ${_currentFps.toStringAsFixed(1)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (_activeSlider == SliderType.confidence)
                  _buildTopPill(
                    '신뢰도 임계값: ${_confidenceThreshold.toStringAsFixed(2)}',
                  ),
                if (_activeSlider == SliderType.iou)
                  _buildTopPill(
                    'IOU 임계값: ${_iouThreshold.toStringAsFixed(2)}',
                  ),
                if (_activeSlider == SliderType.numItems)
                  _buildTopPill('항목 최대: $_numItemsThreshold'),
              ],
            ),
          ),

          Positioned(
            bottom: isLandscape ? 16 : 32,
            right: isLandscape ? 8 : 16,
            child: Column(
              children: [
                _buildCaptureButton(),
                if (!_isFrontCamera) ...[
                  SizedBox(height: isLandscape ? 8 : 12),
                  _buildCircleButton(
                    '${_currentZoomLevel.toStringAsFixed(1)}x',
                    onPressed: () {
                      double nextZoom;
                      if (_currentZoomLevel < 0.75) {
                        nextZoom = 1.0;
                      } else if (_currentZoomLevel < 2.0) {
                        nextZoom = 3.0;
                      } else {
                        nextZoom = 0.5;
                      }
                      _setZoomLevel(nextZoom);
                    },
                  ),
                ],
                SizedBox(height: isLandscape ? 8 : 12),
                _buildIconButton(Icons.layers, () {
                  _toggleSlider(SliderType.numItems);
                }),
                SizedBox(height: isLandscape ? 8 : 12),
                _buildIconButton(Icons.adjust, () {
                  _toggleSlider(SliderType.confidence);
                }),
                SizedBox(height: isLandscape ? 8 : 12),
                _buildIconButton('assets/iou.png', () {
                  _toggleSlider(SliderType.iou);
                }),
                SizedBox(height: isLandscape ? 16 : 40),
              ],
            ),
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + (isLandscape ? 8 : 16),
            right: isLandscape ? 8 : 16,
            child: CircleAvatar(
              radius: isLandscape ? 20 : 24,
              backgroundColor: Colors.black.withAlpha(_kAlpha50Percent),
              child: IconButton(
                icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _isFrontCamera = !_isFrontCamera;
                    if (_isFrontCamera) {
                      _currentZoomLevel = 1.0;
                    }
                  });
                  if (_useController) {
                    _yoloController.switchCamera();
                  } else {
                    _yoloViewKey.currentState?.switchCamera();
                  }
                },
              ),
            ),
          ),

          if (_activeSlider != SliderType.none)
            Positioned(
              bottom: isLandscape ? 16 : 32,
              left: isLandscape ? 8 : 16,
              child: Container(
                width: isLandscape
                    ? MediaQuery.of(context).size.width * 0.4
                    : MediaQuery.of(context).size.width * 0.7,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(_kAlpha60Percent),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Slider(
                  value: _getSliderValue(),
                  min: _getSliderMin(),
                  max: _getSliderMax(),
                  divisions: _getSliderDivisions(),
                  label: _getSliderLabel(),
                  onChanged: _onSliderChanged,
                  activeColor: Colors.white,
                  inactiveColor: Colors.white.withAlpha(_kAlpha30Percent),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIconButton(dynamic iconOrAsset, VoidCallback onPressed) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: Colors.black.withAlpha(_kAlpha20Percent),
      child: IconButton(
        icon: iconOrAsset is IconData
            ? Icon(iconOrAsset, color: Colors.white)
            : Image.asset(
                iconOrAsset,
                width: 24,
                height: 24,
                color: Colors.white,
              ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildCircleButton(String label, {required VoidCallback onPressed}) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: Colors.black.withAlpha(_kAlpha20Percent),
      child: TextButton(
        onPressed: onPressed,
        child: Text(label, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  void _toggleSlider(SliderType type) {
    setState(() {
      _activeSlider = (_activeSlider == type) ? SliderType.none : type;
    });
  }

  Widget _buildTopPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(_kAlpha60Percent),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  double _getSliderValue() {
    switch (_activeSlider) {
      case SliderType.numItems:
        return _numItemsThreshold.toDouble();
      case SliderType.confidence:
        return _confidenceThreshold;
      case SliderType.iou:
        return _iouThreshold;
      default:
        return 0;
    }
  }

  double _getSliderMin() => _activeSlider == SliderType.numItems ? 5 : 0.1;

  double _getSliderMax() => _activeSlider == SliderType.numItems ? 50 : 0.9;

  int _getSliderDivisions() => _activeSlider == SliderType.numItems ? 9 : 8;

  String _getSliderLabel() {
    switch (_activeSlider) {
      case SliderType.numItems:
        return '$_numItemsThreshold';
      case SliderType.confidence:
        return _confidenceThreshold.toStringAsFixed(2);
      case SliderType.iou:
        return _iouThreshold.toStringAsFixed(2);
      default:
        return '';
    }
  }

  void _onSliderChanged(double value) {
    setState(() {
      switch (_activeSlider) {
        case SliderType.numItems:
          _numItemsThreshold = value.toInt();
          break;
        case SliderType.confidence:
          _confidenceThreshold = value;
          break;
        case SliderType.iou:
          _iouThreshold = value;
          break;
        default:
          break;
      }

      if (_useController) {
        _yoloController.setThresholds(
          confidenceThreshold: _confidenceThreshold,
          iouThreshold: _iouThreshold,
          numItemsThreshold: _numItemsThreshold,
        );
      } else {
        _yoloViewKey.currentState?.setThresholds(
          confidenceThreshold: _confidenceThreshold,
          iouThreshold: _iouThreshold,
          numItemsThreshold: _numItemsThreshold,
        );
      }
    });
  }

  void _setZoomLevel(double level) {
    if (_useController) {
      _yoloController.setZoomLevel(level);
    } else {
      _yoloViewKey.currentState?.setZoomLevel(level);
    }
  }

  Future<void> _loadModelForPlatform() async {
    setState(() {
      _isModelLoading = true;
      _loadingMessage = '모델 준비 중...';
    });

    try {
      final path = await _modelManager.getModelPath(_selectedModel);
      setState(() {
        _modelPath = path;
      });
    } catch (e) {
      debugPrint('모델 로딩 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('모델 로딩 실패: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isModelLoading = false;
          _loadingMessage = '';
        });
      }
    }
  }
}
