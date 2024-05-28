import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../services/signalling.service.dart';

class CallScreen extends StatefulWidget {
  final String callerId, calleeId;
  final dynamic offer;
  const CallScreen({
    super.key,
    this.offer,
    required this.callerId,
    required this.calleeId,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  // Socket instance
  final socket = SignallingService.instance.socket;

  // VideoRenderer for localPeer
  final _localRTCVideoRenderer = RTCVideoRenderer();

  // VideoRenderer for remotePeer
  final _remoteRTCVideoRenderer = RTCVideoRenderer();

  // MediaStream for localPeer
  MediaStream? _localStream;

  // RTC peer connection
  RTCPeerConnection? _rtcPeerConnection;

  // List of RTCIceCandidate to be sent over signalling
  List<RTCIceCandidate> rtcIceCandidates = [];

  // Media status
  bool isAudioOn = true, isVideoOn = true, isFrontCameraSelected = true;
  bool callRejected = false;

  @override
  void initState() {
    super.initState();
    _initializeRenderers();
    _setupPeerConnection();
    _listenForCallRejection();
  }

  void _initializeRenderers() async {
    await _localRTCVideoRenderer.initialize();
    await _remoteRTCVideoRenderer.initialize();
  }

  void _listenForCallRejection() {
    SignallingService.instance.onCallRejected((data) {
      if (data['callerId'] == widget.callerId && data['calleeId'] == widget.calleeId) {
        setState(() {
          callRejected = true;
        });
      }
    });
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  _setupPeerConnection() async {
    // Create peer connection
    _rtcPeerConnection = await createPeerConnection({
      'iceServers': [
        {
          'urls': [
            'stun:stun1.l.google.com:19302',
            'stun:stun2.l.google.com:19302'
          ]
        }
      ]
    });

    // Listen for remotePeer mediaTrack event
    _rtcPeerConnection!.onTrack = (event) {
      _remoteRTCVideoRenderer.srcObject = event.streams[0];
      setState(() {});
    };

    // Get localStream
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': isAudioOn,
      'video': isVideoOn
          ? {'facingMode': isFrontCameraSelected ? 'user' : 'environment'}
          : false,
    });

    // Add mediaTrack to peerConnection
    _localStream!.getTracks().forEach((track) {
      _rtcPeerConnection!.addTrack(track, _localStream!);
    });

    // Set source for local video renderer
    _localRTCVideoRenderer.srcObject = _localStream;
    setState(() {});

    // Handle incoming call
    if (widget.offer != null) {
      _handleIncomingCall();
    } else {
      _handleOutgoingCall();
    }

    socket!.on('leaveCall', (data) {
      _handleRemoteLeave();
    });
  }

  _handleIncomingCall() async {
    // Listen for Remote IceCandidate
    socket!.on("IceCandidate", (data) {
      String candidate = data["iceCandidate"]["candidate"];
      String sdpMid = data["iceCandidate"]["id"];
      int sdpMLineIndex = data["iceCandidate"]["label"];

      // Add IceCandidate
      _rtcPeerConnection!.addCandidate(RTCIceCandidate(
        candidate,
        sdpMid,
        sdpMLineIndex,
      ));
    });

    // Set SDP offer as remoteDescription for peerConnection
    await _rtcPeerConnection!.setRemoteDescription(
      RTCSessionDescription(widget.offer["sdp"], widget.offer["type"]),
    );

    // Create SDP answer
    RTCSessionDescription answer = await _rtcPeerConnection!.createAnswer();

    // Set SDP answer as localDescription for peerConnection
    await _rtcPeerConnection!.setLocalDescription(answer);

    // Send SDP answer to remote peer over signalling
    socket!.emit("answerCall", {
      "callerId": widget.callerId,
      "sdpAnswer": answer.toMap(),
    });
  }

  _handleOutgoingCall() async {
    // Listen for local IceCandidate and add it to the list of IceCandidate
    _rtcPeerConnection!.onIceCandidate = (RTCIceCandidate candidate) => rtcIceCandidates.add(candidate);

    // When call is accepted by remote peer
    socket!.on("callAnswered", (data) async {
      // Set SDP answer as remoteDescription for peerConnection
      await _rtcPeerConnection!.setRemoteDescription(
        RTCSessionDescription(
          data["sdpAnswer"]["sdp"],
          data["sdpAnswer"]["type"],
        ),
      );

      // Send IceCandidate generated to remote peer over signalling
      for (RTCIceCandidate candidate in rtcIceCandidates) {
        socket!.emit("IceCandidate", {
          "calleeId": widget.calleeId,
          "iceCandidate": {
            "id": candidate.sdpMid,
            "label": candidate.sdpMLineIndex,
            "candidate": candidate.candidate
          }
        });
      }
    });

    // Create SDP offer
    RTCSessionDescription offer = await _rtcPeerConnection!.createOffer();

    // Set SDP offer as localDescription for peerConnection
    await _rtcPeerConnection!.setLocalDescription(offer);

    // Make a call to remote peer over signalling
    socket!.emit('makeCall', {
      "calleeId": widget.calleeId,
      "sdpOffer": offer.toMap(),
    });
  }

  _leaveCall() {
    socket!.emit('leaveCall', {
      "callerId": widget.callerId,
      "calleeId": widget.calleeId,
    });
    _cleanUp();
    Navigator.pop(context);
  }

  _handleRemoteLeave() {
    _cleanUp();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  _cleanUp() {
    _rtcPeerConnection?.close();
    _rtcPeerConnection = null;
    _localStream?.dispose();
    _remoteRTCVideoRenderer.srcObject = null;
    _localRTCVideoRenderer.srcObject = null;
  }

  _toggleMic() {
    isAudioOn = !isAudioOn;
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = isAudioOn;
    });
    setState(() {});
  }

  _toggleCamera() {
    isVideoOn = !isVideoOn;
    _localStream?.getVideoTracks().forEach((track) {
      track.enabled = isVideoOn;
    });
    setState(() {});
  }

  _switchCamera() {
    isFrontCameraSelected = !isFrontCameraSelected;
    _localStream?.getVideoTracks().forEach((track) {
      track.switchCamera();
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text("P2P Call App"),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  callRejected
                    ? Center(
                        child: Text(
                          'Call Rejected',
                          style: TextStyle(color: Colors.red, fontSize: 24),
                        ),
                      )
                    : RTCVideoView(
                        _remoteRTCVideoRenderer,
                        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      ),
                  Positioned(
                    right: 20,
                    bottom: 20,
                    child: SizedBox(
                      height: 150,
                      width: 120,
                      child: RTCVideoView(
                        _localRTCVideoRenderer,
                        mirror: isFrontCameraSelected,
                        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: Icon(isAudioOn ? Icons.mic : Icons.mic_off),
                    onPressed: _toggleMic,
                  ),
                  IconButton(
                    icon: const Icon(Icons.call_end, color: Colors.red),
                    iconSize: 30,
                    onPressed: _leaveCall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.cameraswitch),
                    onPressed: _switchCamera,
                  ),
                  IconButton(
                    icon: Icon(isVideoOn ? Icons.videocam : Icons.videocam_off),
                    onPressed: _toggleCamera,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cleanUp();
    _localRTCVideoRenderer.dispose();
    _remoteRTCVideoRenderer.dispose();
    _localStream?.dispose();
    _rtcPeerConnection?.dispose();
    super.dispose();
  }
}
