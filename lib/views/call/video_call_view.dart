import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VideoCallView extends StatefulWidget {
  final String channelName; // session doc id
  const VideoCallView({super.key, required this.channelName});

  @override
  State<VideoCallView> createState() => _VideoCallViewState();
}

class _VideoCallViewState extends State<VideoCallView> {
  static const String appId = 'ab119a77c156487782e29244245bc6f8';
  RtcEngine? _engine;
  int? _remoteUid;
  bool _localMuted = false;
  bool _localVideoDisabled = false;
  bool _isConnecting = true;
  String _connectionStatus = 'Initializing...';
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() {
      _connectionStatus = 'Requesting permissions...';
    });

    // Request permissions
    final permissions = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    // Check if permissions are granted
    if (permissions[Permission.camera] != PermissionStatus.granted ||
        permissions[Permission.microphone] != PermissionStatus.granted) {
      setState(() {
        _hasError = true;
        _errorMessage =
            'Camera and microphone permissions are required for video calls';
        _isConnecting = false;
      });
      return;
    }

    try {
      setState(() {
        _connectionStatus = 'Initializing Agora engine...';
      });

      final engine = createAgoraRtcEngine();
      _engine = engine;

      await engine.initialize(const RtcEngineContext(appId: appId));

      engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint(
              'Local user ${connection.localUid} joined channel successfully',
            );
            setState(() {
              _isConnecting = false;
              _connectionStatus = 'Connected - Waiting for remote user...';
            });
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            debugPrint('Remote user $remoteUid joined channel');
            setState(() {
              _remoteUid = remoteUid;
              _connectionStatus = 'Remote user connected';
            });
          },
          onUserOffline:
              (
                RtcConnection connection,
                int remoteUid,
                UserOfflineReasonType reason,
              ) {
                debugPrint('Remote user $remoteUid left channel');
                setState(() {
                  _remoteUid = null;
                  _connectionStatus = 'Remote user disconnected';
                });
              },
          onError: (ErrorCodeType err, String msg) {
            debugPrint('Agora error: $err - $msg');
            setState(() {
              _hasError = true;
              _errorMessage = 'Connection error: $msg';
              _isConnecting = false;
            });
          },
          onConnectionStateChanged:
              (
                RtcConnection connection,
                ConnectionStateType state,
                ConnectionChangedReasonType reason,
              ) {
                debugPrint('Connection state changed: $state, reason: $reason');
                String status = '';
                switch (state) {
                  case ConnectionStateType.connectionStateConnecting:
                    status = 'Connecting...';
                    break;
                  case ConnectionStateType.connectionStateConnected:
                    status = 'Connected';
                    break;
                  case ConnectionStateType.connectionStateReconnecting:
                    status = 'Reconnecting...';
                    break;
                  case ConnectionStateType.connectionStateFailed:
                    status = 'Connection failed';
                    setState(() {
                      _hasError = true;
                      _errorMessage = 'Failed to connect to video call';
                    });
                    break;
                  default:
                    status = 'Disconnected';
                }
                setState(() {
                  _connectionStatus = status;
                });
              },
        ),
      );

      setState(() {
        _connectionStatus = 'Enabling video and audio...';
      });

      await engine.enableVideo();
      await engine.enableAudio();
      await engine.startPreview();

      setState(() {
        _connectionStatus = 'Joining channel...';
      });

      // For testing purposes, using empty token.
      // In production, you should implement a token server
      await engine.joinChannel(
        token: '',
        channelId: widget.channelName,
        uid: 0,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );
    } catch (e) {
      debugPrint('Error initializing video call: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to initialize video call: ${e.toString()}';
        _isConnecting = false;
      });
    }
  }

  @override
  void dispose() {
    _cleanupEngine();
    super.dispose();
  }

  Future<void> _cleanupEngine() async {
    final engine = _engine;
    if (engine != null) {
      try {
        await engine.leaveChannel();
        await engine.release();
        _engine = null;

        // Mark session as completed when call ends
        await _markSessionCompleted();
      } catch (e) {
        debugPrint('Error during cleanup: $e');
      }
    }
  }

  Future<void> _markSessionCompleted() async {
    try {
      await FirebaseFirestore.instance
          .collection('session')
          .doc(widget.channelName)
          .update({
            'status': 'completed',
            'endTime': FieldValue.serverTimestamp(),
          });
      debugPrint('Session marked as completed');
    } catch (e) {
      debugPrint('Error marking session as completed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Call: ${widget.channelName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_end),
            onPressed: () => Get.back(),
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: _hasError
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Connection Error',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _errorMessage,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () {
                          setState(() {
                            _hasError = false;
                            _errorMessage = '';
                            _isConnecting = true;
                          });
                          _init();
                        },
                        child: const Text('Retry'),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Troubleshooting Tips'),
                              content: const SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('1. Check your internet connection'),
                                    SizedBox(height: 8),
                                    Text(
                                      '2. Ensure camera and microphone permissions are granted',
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      '3. Close other apps using camera/microphone',
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      '4. Restart the app if the issue persists',
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      '5. Make sure both users are using the same channel ID',
                                    ),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        },
                        child: const Text('Troubleshooting'),
                      ),
                    ],
                  )
                : _engine == null || _isConnecting
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        _connectionStatus,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  )
                : _remoteUid != null
                ? AgoraVideoView(
                    controller: VideoViewController.remote(
                      rtcEngine: _engine!,
                      canvas: VideoCanvas(uid: _remoteUid),
                      connection: RtcConnection(channelId: widget.channelName),
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Waiting for the other user to join...',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _connectionStatus,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
          ),
          Positioned(
            right: 16,
            bottom: 120,
            child: SizedBox(
              width: 120,
              height: 160,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white70),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _engine == null || _hasError
                    ? const SizedBox.shrink()
                    : _localVideoDisabled
                    ? Container(
                        color: Colors.black87,
                        child: const Center(
                          child: Icon(
                            Icons.videocam_off,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      )
                    : AgoraVideoView(
                        controller: VideoViewController(
                          rtcEngine: _engine!,
                          canvas: const VideoCanvas(uid: 0),
                        ),
                      ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: (_engine == null || _hasError)
                        ? null
                        : () async {
                            // Toggle local audio by maintaining a bool
                            _localMuted = !_localMuted;
                            await _engine!.muteLocalAudioStream(_localMuted);
                            setState(() {});
                          },
                    icon: Icon(_localMuted ? Icons.mic_off : Icons.mic),
                    label: Text(_localMuted ? 'Unmute' : 'Mute'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: (_engine == null || _hasError)
                        ? null
                        : () async {
                            _localVideoDisabled = !_localVideoDisabled;
                            await _engine!.muteLocalVideoStream(
                              _localVideoDisabled,
                            );
                            setState(() {});
                          },
                    icon: Icon(
                      _localVideoDisabled ? Icons.videocam_off : Icons.videocam,
                    ),
                    label: Text(_localVideoDisabled ? 'Video Off' : 'Video On'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: (_engine == null || _hasError)
                        ? null
                        : () async {
                            await _engine!.switchCamera();
                          },
                    icon: const Icon(Icons.cameraswitch),
                    label: const Text('Switch'),
                  ),
                ],
              ),
            ),
          ),
          // Connection status indicator
          if (!_hasError && _engine != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _remoteUid != null
                      ? Colors.green.withValues(alpha: 0.9)
                      : Colors.orange.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _remoteUid != null
                          ? Icons.videocam
                          : Icons.hourglass_empty,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _connectionStatus,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
