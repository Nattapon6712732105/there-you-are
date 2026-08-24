import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_service.dart';
import '../services/device_service.dart';
import '../services/permission_service.dart';
import '../my_home_page.dart';
import 'welcome_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool autoPromptPermission;

  const HomeScreen({
    super.key,
    this.autoPromptPermission = true,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _api = ApiService();
  int _currentIndex = 0;

  User? _user;
  List<CheckIn> _checkIns = [];
  bool _loadingUser = true;
  bool _loadingFeed = true;
  bool _isSystemHealthy = false;
  DeviceDetails? _deviceDetails;

  @override
  void initState() {
    super.initState();
    _initData();
    if (widget.autoPromptPermission) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAndPromptHardwarePermissions();
      });
    }
  }

  Future<void> _checkAndPromptHardwarePermissions() async {
    if (!mounted) return;
    await PermissionService.showPermissionDialog(context);
  }

  void _initData() {
    // 1. Priority 1: Load Profile & Feed immediately for fast first render
    _loadProfile();
    _loadCheckIns();

    // 2. Priority 2: Defer background tasks slightly to unblock main UI thread
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _loadDeviceInfo();
        _checkHealthStatus();
      }
    });
  }

  Future<void> _loadDeviceInfo() async {
    final info = await DeviceService.getDeviceDetails();
    if (mounted) {
      setState(() => _deviceDetails = info);
    }
  }

  Future<void> _checkHealthStatus() async {
    final healthy = await _api.checkHealth();
    if (mounted) {
      setState(() => _isSystemHealthy = healthy);
    }
  }

  Future<void> _loadProfile() async {
    final token = await _api.getToken();
    if (token == null) {
      if (!mounted) return;
      _navigateToLogin();
      return;
    }
    try {
      final user = await _api.me(token: token);
      if (!mounted) return;
      setState(() {
        _user = user;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401 || e.statusCode == 403) {
        await _api.clearToken();
        if (!mounted) return;
        _navigateToLogin();
        return;
      }
    } catch (e, st) {
      debugPrint('[HomeScreen] _loadProfile error: $e\n$st');
    } finally {
      if (mounted) {
        setState(() => _loadingUser = false);
      }
    }
  }

  Future<void> _loadCheckIns() async {
    try {
      final list = await _api.getCheckIns();
      if (!mounted) return;
      setState(() {
        _checkIns = list;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } catch (e, st) {
      debugPrint('[HomeScreen] _loadCheckIns unexpected error: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loadingFeed = false);
      }
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  Future<void> _openGoogleMaps(double lat, double lng) async {
    final googleMapsUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng');

    try {
      if (await canLaunchUrl(googleMapsUri)) {
        await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(geoUri)) {
        await launchUrl(geoUri, mode: LaunchMode.externalApplication);
      } else {
        final success = await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
        if (!success) {
          await launchUrl(googleMapsUri, mode: LaunchMode.platformDefault);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถเปิด Google Maps ได้: $e')),
      );
    }
  }

  void _showAllCheckInsMapDialog() {
    if (_checkIns.isEmpty) return;

    double avgLat =
        _checkIns.map((e) => e.lat).reduce((a, b) => a + b) / _checkIns.length;
    double avgLng =
        _checkIns.map((e) => e.lng).reduce((a, b) => a + b) / _checkIns.length;

    CheckIn? selectedItem;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => Dialog.fullscreen(
          child: Scaffold(
            appBar: AppBar(
              title: Text('แผนที่รวมตำแหน่ง (${_checkIns.length} จุด)'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(dialogCtx),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.my_location),
                  tooltip: 'พิกัดกลาง',
                  onPressed: () => setDialogState(() => selectedItem = null),
                ),
              ],
            ),
            body: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(avgLat, avgLng),
                    initialZoom: 12,
                    onTap: (tapPos, latLng) =>
                        setDialogState(() => selectedItem = null),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.there_you_are',
                    ),
                    MarkerLayer(
                      markers: _checkIns.map((item) {
                        final isSelected = selectedItem?.id == item.id;
                        return Marker(
                          point: LatLng(item.lat, item.lng),
                          width: isSelected ? 48 : 36,
                          height: isSelected ? 48 : 36,
                          child: GestureDetector(
                            onTap: () {
                              setDialogState(() => selectedItem = item);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF0F766E)
                                    : Colors.redAccent,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 6,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.person_pin_circle_rounded,
                                color: Colors.white,
                                size: isSelected ? 30 : 22,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                if (selectedItem != null)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 24,
                    child: Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundImage: (selectedItem!
                                                  .user?.profileImage !=
                                              null &&
                                          selectedItem!
                                              .user!.profileImage!.isNotEmpty)
                                      ? NetworkImage(
                                          selectedItem!.user!.profileImage!)
                                      : null,
                                  child: (selectedItem!.user?.profileImage ==
                                              null ||
                                          selectedItem!
                                              .user!.profileImage!.isEmpty)
                                      ? Text(selectedItem!.user?.name?[0]
                                              .toUpperCase() ??
                                          '?')
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        selectedItem!.user?.name ??
                                            'สมาชิกทั่วไป',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        selectedItem!.locationName ??
                                            'ไม่ได้ระบุชื่อสถานที่',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF0F766E),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 20),
                                  onPressed: () =>
                                      setDialogState(() => selectedItem = null),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '📍 Lat: ${selectedItem!.lat} • Lng: ${selectedItem!.lng}',
                              style: TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => _openGoogleMaps(
                                      selectedItem!.lat, selectedItem!.lng),
                                  icon: const Icon(Icons.map_rounded, size: 16),
                                  label: const Text('เปิดใน Google Maps'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('ออกจากระบบ'),
        content: const Text('คุณต้องการออกจากระบบหรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ออกจากระบบ'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final token = await _api.getToken();
    await _api.logout(token: token);
    if (!mounted) return;
    _navigateToLogin();
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('ลบบัญชีผู้ใช้'),
        content: const Text(
          'คุณแน่ใจหรือไม่ว่าต้องการลบบัญชีนี้? การกระทำนี้ไม่สามารถย้อนกลับได้',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ลบบัญชี'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final token = await _api.getToken();
    if (token == null) return;

    try {
      await _api.deleteAccount(token: token);
      await _api.clearToken();
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('ลบบัญชีผู้ใช้เรียบร้อยแล้ว')),
      );
      _navigateToLogin();
    } on ApiException catch (e) {
      await _api.clearToken();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('ลบบัญชีแล้ว: ${e.message}'),
          backgroundColor: Colors.orange.shade800,
        ),
      );
      _navigateToLogin();
    }
  }

  Future<void> _showCreateCheckInDialog() async {
    final token = await _api.getToken();
    if (token == null) {
      _navigateToLogin();
      return;
    }

    final formKey = GlobalKey<FormState>();
    final latCtrl = TextEditingController();
    final lngCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final imgCtrl = TextEditingController();
    bool saving = false;
    bool fetchingLocation = true;
    bool initialLocationFetched = false;

    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final dialogNavigator = Navigator.of(ctx);
        final messenger = ScaffoldMessenger.of(context);
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            if (!initialLocationFetched) {
              initialLocationFetched = true;
              PermissionService.getCurrentPositionWithResult().then((res) {
                if (mounted) {
                  setDialogState(() {
                    if (res.isSuccess) {
                      latCtrl.text = res.position!.latitude.toStringAsFixed(6);
                      lngCtrl.text = res.position!.longitude.toStringAsFixed(6);
                    } else {
                      if (res.errorMessage != null) {
                        messenger.showSnackBar(
                          SnackBar(content: Text(res.errorMessage!)),
                        );
                      }
                    }
                    fetchingLocation = false;
                  });
                }
              });
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.add_location_alt_rounded,
                      color: Color(0xFF0F766E)),
                  SizedBox(width: 8),
                  Text('สร้างการ Check-in ใหม่'),
                ],
              ),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'ชื่อสถานที่',
                          prefixIcon: Icon(Icons.place_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'กรุณากรอกชื่อสถานที่'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.my_location_rounded,
                                  size: 16, color: Color(0xFF0F766E)),
                              SizedBox(width: 4),
                              Text(
                                'พิกัด GPS ปัจจุบัน',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F766E),
                                ),
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: fetchingLocation
                                ? null
                                : () async {
                                    setDialogState(
                                        () => fetchingLocation = true);
                                    final res = await PermissionService
                                        .getCurrentPositionWithResult();
                                    setDialogState(() {
                                      if (res.isSuccess) {
                                        latCtrl.text =
                                            res.position!.latitude.toStringAsFixed(6);
                                        lngCtrl.text =
                                            res.position!.longitude.toStringAsFixed(6);
                                      } else {
                                        if (res.errorMessage != null) {
                                          messenger.showSnackBar(
                                            SnackBar(
                                                content: Text(res.errorMessage!)),
                                          );
                                        }
                                      }
                                      fetchingLocation = false;
                                    });
                                  },
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              child: Row(
                                children: [
                                  if (fetchingLocation)
                                    const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  else
                                    const Icon(Icons.refresh_rounded,
                                        size: 14, color: Color(0xFF0F766E)),
                                  const SizedBox(width: 4),
                                  Text(
                                    fetchingLocation
                                        ? 'กำลังดึงพิกัด...'
                                        : 'ดึงพิกัดสด',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF0F766E),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: latCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true, signed: true),
                              decoration: const InputDecoration(
                                labelText: 'Latitude',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => double.tryParse(v ?? '') == null
                                  ? 'ผิด'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: lngCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true, signed: true),
                              decoration: const InputDecoration(
                                labelText: 'Longitude',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => double.tryParse(v ?? '') == null
                                  ? 'ผิด'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'รายละเอียด / ข้อความ',
                          prefixIcon: Icon(Icons.notes_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ImagePickerField(controller: imgCtrl),
                    ],
                  ),
                ),
              ),
            ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => dialogNavigator.pop(),
                  child: const Text('ยกเลิก'),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => saving = true);
                          try {
                            await _api.createCheckIn(
                              token: token,
                              lat: double.parse(latCtrl.text),
                              lng: double.parse(lngCtrl.text),
                              locationName: nameCtrl.text.trim(),
                              description: descCtrl.text.trim(),
                              imageUrl: imgCtrl.text.trim(),
                            );
                            dialogNavigator.pop();
                            messenger.showSnackBar(
                              const SnackBar(
                                  content: Text('สร้างการ Check-in สำเร็จ!')),
                            );
                            _loadCheckIns();
                          } on ApiException catch (e) {
                            setDialogState(() => saving = false);
                            messenger.showSnackBar(
                              SnackBar(
                                  content: Text(e.message),
                                  backgroundColor: Colors.red),
                            );
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('บันทึก'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showLocationMapModal(CheckIn item) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 480),
          child: Padding(
            padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.place_rounded, color: Color(0xFF0F766E)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.locationName ?? 'ตำแหน่งบนแผนที่',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(item.lat, item.lng),
                      initialZoom: 15,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.there_you_are',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(item.lat, item.lng),
                            width: 48,
                            height: 48,
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: Colors.redAccent,
                              size: 44,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '📍 ${item.lat.toStringAsFixed(4)}, ${item.lng.toStringAsFixed(4)}',
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _openGoogleMaps(item.lat, item.lng);
                        },
                        icon: const Icon(Icons.open_in_new_rounded, size: 14),
                        label: const Text('Google Maps', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      const SizedBox(width: 6),
                      FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text('ปิด', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Future<void> _showEditCheckInDialog(CheckIn item) async {
    final token = await _api.getToken();
    if (token == null) {
      _navigateToLogin();
      return;
    }

    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: item.locationName ?? '');
    final descCtrl = TextEditingController(text: item.description ?? '');
    final latCtrl = TextEditingController(text: item.lat.toString());
    final lngCtrl = TextEditingController(text: item.lng.toString());
    final imgCtrl = TextEditingController(text: item.imageUrl ?? '');
    bool saving = false;
    bool fetchingLocation = false;

    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final dialogNavigator = Navigator.of(ctx);
        final messenger = ScaffoldMessenger.of(context);
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.edit_location_alt_rounded, color: Color(0xFF0F766E)),
                SizedBox(width: 8),
                Text('แก้ไขการ Check-in'),
              ],
            ),
            content: SizedBox(
              width: 450,
              child: SingleChildScrollView(
                child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'ชื่อสถานที่',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'กรุณากรอกชื่อสถานที่'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.my_location_rounded,
                                size: 16, color: Color(0xFF0F766E)),
                            SizedBox(width: 4),
                            Text(
                              'พิกัด GPS',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F766E),
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: fetchingLocation
                              ? null
                              : () async {
                                  setDialogState(
                                      () => fetchingLocation = true);
                                  final pos = await PermissionService
                                      .getCurrentPosition();
                                  setDialogState(() {
                                    if (pos != null) {
                                      latCtrl.text =
                                          pos.latitude.toStringAsFixed(6);
                                      lngCtrl.text =
                                          pos.longitude.toStringAsFixed(6);
                                    } else {
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'ไม่สามารถดึงพิกัด GPS ได้ กรุณาเปิด Location บนเครื่อง'),
                                        ),
                                      );
                                    }
                                    fetchingLocation = false;
                                  });
                                },
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            child: Row(
                              children: [
                                if (fetchingLocation)
                                  const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                else
                                  const Icon(Icons.refresh_rounded,
                                      size: 14, color: Color(0xFF0F766E)),
                                const SizedBox(width: 4),
                                Text(
                                  fetchingLocation
                                      ? 'กำลังดึงพิกัด...'
                                      : 'ใช้ตำแหน่งปัจจุบัน',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF0F766E),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: latCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true, signed: true),
                            decoration: const InputDecoration(
                              labelText: 'Latitude',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: lngCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true, signed: true),
                            decoration: const InputDecoration(
                              labelText: 'Longitude',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'รายละเอียด / ข้อความ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ImagePickerField(controller: imgCtrl),
                  ],
                ),
              ),
            ),
          ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => dialogNavigator.pop(),
                child: const Text('ยกเลิก'),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => saving = true);
                        try {
                          await _api.updateCheckIn(
                            token: token,
                            id: item.id,
                            lat: double.tryParse(latCtrl.text),
                            lng: double.tryParse(lngCtrl.text),
                            locationName: nameCtrl.text.trim(),
                            description: descCtrl.text.trim(),
                            imageUrl: imgCtrl.text.trim(),
                          );
                          dialogNavigator.pop();
                          messenger.showSnackBar(
                            const SnackBar(
                                content: Text('อัปเดตการ Check-in แล้ว')),
                          );
                          _loadCheckIns();
                        } on ApiException catch (e) {
                          setDialogState(() => saving = false);
                          messenger.showSnackBar(
                            SnackBar(
                                content: Text(e.message),
                                backgroundColor: Colors.red),
                          );
                        }
                      },
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('บันทึกการแก้ไข'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteCheckIn(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('ลบโพสต์ Check-in'),
        content: const Text('คุณแน่ใจหรือไม่ว่าต้องการลบ Check-in นี้?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final token = await _api.getToken();
    if (token == null) return;
    try {
      await _api.deleteCheckIn(token: token, id: id);
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('ลบ Check-in สำเร็จ')),
      );
      _loadCheckIns();
    } on ApiException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showEditProfileDialog() async {
    final token = await _api.getToken();
    if (token == null) return;

    final nameCtrl = TextEditingController(text: _user?.name ?? '');
    bool saving = false;

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) {
        final dialogNavigator = Navigator.of(ctx);
        final messenger = ScaffoldMessenger.of(context);
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('แก้ไขชื่อผู้ใช้'),
            content: TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'ชื่อ-นามสกุล',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => dialogNavigator.pop(),
                child: const Text('ยกเลิก'),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        final newName = nameCtrl.text.trim();
                        if (newName.isEmpty) return;
                        setDialogState(() => saving = true);
                        try {
                          final updatedUser = await _api.updateProfile(
                            token: token,
                            name: newName,
                          );
                          if (mounted) {
                            setState(() => _user = updatedUser);
                          }
                          dialogNavigator.pop();
                          messenger.showSnackBar(
                            const SnackBar(
                                content:
                                    Text('อัปเดตข้อมูลโปรไฟล์เรียบร้อยแล้ว')),
                          );
                        } on ApiException catch (e) {
                          setDialogState(() => saving = false);
                          messenger.showSnackBar(
                            SnackBar(
                                content: Text(e.message),
                                backgroundColor: Colors.red),
                          );
                        }
                      },
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('บันทึก'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final token = await _api.getToken();
    if (token == null) return;

    final formKey = GlobalKey<FormState>();
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    bool saving = false;

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) {
        final dialogNavigator = Navigator.of(ctx);
        final messenger = ScaffoldMessenger.of(context);
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('เปลี่ยนรหัสผ่าน'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: oldPassCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'รหัสผ่านเดิม',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'กรุณากรอกรหัสผ่านเดิม' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: newPassCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'รหัสผ่านใหม่ (อย่างน้อย 8 ตัวอักษร)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.length < 8
                        ? 'รหัสผ่านต้องอย่างน้อย 8 ตัวอักษร'
                        : null,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => dialogNavigator.pop(),
                child: const Text('ยกเลิก'),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => saving = true);
                        try {
                          await _api.changePassword(
                            token: token,
                            oldPassword: oldPassCtrl.text,
                            newPassword: newPassCtrl.text,
                          );
                          dialogNavigator.pop();
                          messenger.showSnackBar(
                            const SnackBar(
                                content: Text('เปลี่ยนรหัสผ่านสำเร็จ!')),
                          );
                        } on ApiException catch (e) {
                          setDialogState(() => saving = false);
                          messenger.showSnackBar(
                            SnackBar(
                                content: Text(e.message),
                                backgroundColor: Colors.red),
                          );
                        }
                      },
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('เปลี่ยนรหัสผ่าน'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/img/app_icon.png',
                width: 32,
                height: 32,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'There You Are',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const Spacer(),

            // ==========================================
            // PREMIUM DEVICE BADGE ON APPBAR
            // ==========================================
            if (_deviceDetails != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _deviceDetails!.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _deviceDetails!.color.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _deviceDetails!.icon,
                      size: 14,
                      color: _deviceDetails!.color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _deviceDetails!.platformName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _deviceDetails!.color,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(width: 8),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'รีเฟรชข้อมูล',
            onPressed: () {
              setState(() => _loadingFeed = true);
              _loadProfile();
              _loadCheckIns();
              _checkHealthStatus();
              _loadDeviceInfo();
            },
          ),
        ],
      ),
      body: _currentIndex == 0 ? _buildFeedTab() : _buildProfileTab(),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _showCreateCheckInDialog,
              icon: const Icon(Icons.add_location_alt_rounded),
              label: const Text(
                'Check-in',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              elevation: 4,
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) =>
            setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded),
            label: 'Check-ins Feed',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'โปรไฟล์ & อุปกรณ์',
          ),
        ],
      ),
    );
  }

  Widget _buildFeedTab() {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _loadingFeed = true);
        await _loadCheckIns();
        await _checkHealthStatus();
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // ==========================================
          // PREMIUM DASHBOARD HEADER BANNER (ALWAYS VISIBLE IMMEDIATELY)
          // ==========================================
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF0F766E),
                  Color(0xFF047857),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F766E).withValues(alpha: 0.25),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ยินดีต้อนรับกลับมา 👋',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _user?.name ?? 'สมาชิก มีระดับ',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // API Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isSystemHealthy
                              ? Colors.greenAccent
                              : Colors.orangeAccent,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _isSystemHealthy
                                  ? Colors.greenAccent
                                  : Colors.orangeAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isSystemHealthy ? 'API ONLINE' : 'API OFFLINE',
                            style: TextStyle(
                              color: _isSystemHealthy
                                  ? Colors.greenAccent
                                  : Colors.orangeAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 14),

                // Device Info Details Bar
                Row(
                  children: [
                    Icon(
                      _deviceDetails?.icon ?? Icons.devices_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'อุปกรณ์ปัจจุบัน: ${_deviceDetails?.modelName ?? 'กำลังตรวจสอบ...'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Feed Header Title
          Row(
            children: [
              const Expanded(
                child: Text(
                  '📍 ฟีดการ Check-in ล่าสุด',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              if (_checkIns.isNotEmpty)
                ActionChip(
                  avatar: const Icon(Icons.map_rounded,
                      size: 14, color: Color(0xFF0F766E)),
                  label: Text('ดูแผนที่รวม (${_checkIns.length})',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F766E))),
                  onPressed: _showAllCheckInsMapDialog,
                  backgroundColor: const Color(0xFF0F766E).withValues(alpha: 0.1),
                  visualDensity: VisualDensity.compact,
                )
              else
                Chip(
                  label: const Text('0 รายการ'),
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  labelStyle: const TextStyle(fontSize: 11),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),

          const SizedBox(height: 12),

          // ==========================================
          // IN-PLACE FEED CONTENT OR LOADING SPINNER
          // ==========================================
          if (_loadingFeed)
            Container(
              padding: const EdgeInsets.all(40),
              child: const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'กำลังโหลดข้อมูลการ Check-in จาก API...',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            )
          else if (_checkIns.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(Icons.location_off_outlined,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text(
                    'ยังไม่มีรายการ Check-in ในขณะนี้',
                    style: TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _loadingFeed = true);
                      _loadCheckIns();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('รีเฟรชลองใหม่อีกครั้ง'),
                  ),
                ],
              ),
            )
          else
            ..._checkIns.map((item) {
              final isOwner = _user != null && item.user?.id == _user!.id;
              final formattedDate = item.createdAt != null
                  ? '${item.createdAt!.day}/${item.createdAt!.month}/${item.createdAt!.year} ${item.createdAt!.hour.toString().padLeft(2, '0')}:${item.createdAt!.minute.toString().padLeft(2, '0')}'
                  : '';

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 3,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: (item.user?.profileImage != null &&
                                    item.user!.profileImage!.isNotEmpty)
                                ? NetworkImage(item.user!.profileImage!)
                                : null,
                            child: (item.user?.profileImage == null ||
                                    item.user!.profileImage!.isEmpty)
                                ? Text(
                                    (item.user?.name?.isNotEmpty ?? false)
                                        ? item.user!.name![0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      item.user?.name ?? 'สมาชิกทั่วไป',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    if (isOwner) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: Colors.deepPurple.shade100,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'คุณ',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.deepPurple,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (formattedDate.isNotEmpty)
                                  Text(
                                    formattedDate,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (isOwner)
                            PopupMenuButton<String>(
                              onSelected: (val) {
                                if (val == 'edit') {
                                  _showEditCheckInDialog(item);
                                } else if (val == 'delete') {
                                  _deleteCheckIn(item.id);
                                }
                              },
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 18),
                                      SizedBox(width: 8),
                                      Text('แก้ไข'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete,
                                          size: 18, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('ลบ',
                                          style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // ==========================================
                      // LOCATION HEADER & GOOGLE MAPS LINK
                      // ==========================================
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F766E).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.place_rounded,
                                color: Color(0xFF0F766E), size: 20),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                item.locationName ?? 'ไม่ได้ระบุชื่อสถานที่',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '📍 Lat: ${item.lat.toStringAsFixed(4)} • Lng: ${item.lng.toStringAsFixed(4)}',
                              style: TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color: Colors.grey.shade700,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => _openGoogleMaps(item.lat, item.lng),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.map_rounded,
                                      size: 14, color: Colors.blueAccent),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Google Maps',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blueAccent.shade700,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      // ==========================================
                      // INLINE MAP PREVIEW (DIRECTLY VISIBLE ON CARD)
                      // ==========================================
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          onTap: () => _showLocationMapModal(item),
                          child: Container(
                            height: 160,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Stack(
                              children: [
                                ExcludeSemantics(
                                  child: FlutterMap(
                                    options: MapOptions(
                                      initialCenter: LatLng(item.lat, item.lng),
                                      initialZoom: 14,
                                      interactionOptions: const InteractionOptions(
                                        flags: InteractiveFlag.none,
                                      ),
                                    ),
                                    children: [
                                      TileLayer(
                                        urlTemplate:
                                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                        userAgentPackageName: 'com.example.there_you_are',
                                      ),
                                      MarkerLayer(
                                        markers: [
                                          Marker(
                                            point: LatLng(item.lat, item.lng),
                                            width: 38,
                                            height: 38,
                                            child: const Icon(
                                              Icons.location_on_rounded,
                                              color: Colors.redAccent,
                                              size: 36,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  right: 8,
                                  bottom: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.65),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.touch_app_rounded, color: Colors.white, size: 12),
                                        SizedBox(width: 4),
                                        Text(
                                          'แตะเพื่อเปิดแผนที่ขยาย',
                                          style: TextStyle(color: Colors.white, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (item.description != null &&
                          item.description!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          item.description!,
                          style: const TextStyle(fontSize: 14, height: 1.3),
                        ),
                      ],
                      if (item.imageUrl != null &&
                          item.imageUrl!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _buildImageWidget(item.imageUrl!, height: 220),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    if (_loadingUser) {
      return const Center(child: CircularProgressIndicator());
    }
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () async {
        await _loadProfile();
        await _loadDeviceInfo();
      },
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ==========================================
          // PREMIUM PROFILE CARD
          // ==========================================
          Card(
            elevation: 4,
            shadowColor: const Color(0xFF0F766E).withValues(alpha: 0.15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundImage: (_user?.avatarUrl != null &&
                            _user!.avatarUrl!.isNotEmpty)
                        ? NetworkImage(_user!.avatarUrl!)
                        : null,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: (_user?.avatarUrl == null ||
                            _user!.avatarUrl!.isEmpty)
                        ? Text(
                            (_user?.name?.isNotEmpty ?? false)
                                ? _user!.name![0].toUpperCase()
                                : '?',
                            style: theme.textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _user?.name ?? 'ผู้ใช้งาน',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _user?.email ?? '',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _user != null && !_user!.isVerified
                      ? Chip(
                          avatar: Icon(Icons.warning_amber_rounded,
                              size: 18, color: theme.colorScheme.error),
                          label: const Text('ยังไม่ได้ยืนยันอีเมล OTP'),
                          backgroundColor: Colors.red.withValues(alpha: 0.1),
                        )
                      : Chip(
                          avatar: const Icon(Icons.verified_rounded,
                              size: 18, color: Color(0xFF10B981)),
                          label: const Text(
                              'ยืนยันตัวตนเรียบร้อยแล้ว (OTP Verified)'),
                          backgroundColor:
                              const Color(0xFF10B981).withValues(alpha: 0.1),
                        ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ==========================================
          // PREMIUM ACTIVE DEVICE CARD (ลักษณะเฉพาะตัวอุปกรณ์)
          // ==========================================
          if (_deviceDetails != null)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _deviceDetails!.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _deviceDetails!.icon,
                            color: _deviceDetails!.color,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '📱 อุปกรณ์ที่คุณกำลังใช้งาน',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _deviceDetails!.modelName,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'แพลตฟอร์ม: ${_deviceDetails!.platformName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _deviceDetails!.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Active Machine',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _deviceDetails!.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 20),

          // ==========================================
          // ACCOUNT SETTINGS LIST
          // ==========================================
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.edit_outlined,
                      color: Color(0xFF0F766E)),
                  title: const Text('แก้ไขชื่อผู้ใช้'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _showEditProfileDialog,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.lock_reset_outlined,
                      color: Colors.indigo),
                  title: const Text('เปลี่ยนรหัสผ่าน'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _showChangePasswordDialog,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.security_rounded,
                      color: Colors.blueAccent),
                  title: const Text('จัดการสิทธิ์อุปกรณ์ (Permissions)'),
                  subtitle: const Text(' Location, Camera & Storage'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => PermissionService.showPermissionDialog(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.shield_outlined,
                      color: Color(0xFF0F766E)),
                  title: const Text('เงื่อนไขการใช้งาน & นโยบาย PDPA'),
                  subtitle: const Text('รายงานการคุ้มครองข้อมูลส่วนบุคคล พ.ร.บ. 2562'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MyHomePage()),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.dns_outlined, color: Colors.green),
                  title: const Text('สถานะการเชื่อมต่อ API Server'),
                  subtitle:
                      Text(_isSystemHealthy ? 'ONLINE (200 OK)' : 'OFFLINE'),
                  trailing: Icon(
                    Icons.circle,
                    size: 12,
                    color: _isSystemHealthy ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Logout and Delete Account
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.logout_rounded,
                      color: Colors.orangeAccent),
                  title: const Text(
                    'ออกจากระบบ',
                    style: TextStyle(
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.bold),
                  ),
                  onTap: _logout,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_forever_rounded,
                      color: Colors.red),
                  title: const Text(
                    'ลบบัญชีผู้ใช้ถาวร',
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                  onTap: _deleteAccount,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

Widget _buildImageWidget(String imageUrl, {double height = 220, BoxFit fit = BoxFit.cover}) {
  if (imageUrl.isEmpty) return const SizedBox.shrink();

  if (imageUrl.startsWith('data:image/') || imageUrl.startsWith('data:application/')) {
    try {
      final base64Data = imageUrl.split(',').last;
      final bytes = base64Decode(base64Data);
      return Image.memory(
        bytes,
        height: height,
        fit: fit,
        errorBuilder: (ctx, err, stack) => _buildImageErrorWidget(),
      );
    } catch (_) {
      return _buildImageErrorWidget();
    }
  } else {
    return Image.network(
      imageUrl,
      height: height,
      fit: fit,
      errorBuilder: (ctx, err, stack) => _buildImageErrorWidget(),
    );
  }
}

Widget _buildImageErrorWidget() {
  return Container(
    height: 120,
    color: Colors.grey.shade200,
    alignment: Alignment.center,
    child: const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.broken_image_rounded, color: Colors.grey),
        SizedBox(height: 4),
        Text('ไม่สามารถโหลดรูปภาพได้', style: TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    ),
  );
}

class _ImagePickerField extends StatefulWidget {
  final TextEditingController controller;

  const _ImagePickerField({
    required this.controller,
  });

  @override
  State<_ImagePickerField> createState() => _ImagePickerFieldState();
}

class _ImagePickerFieldState extends State<_ImagePickerField> {
  bool _showUrlInput = false;

  Future<void> _pick(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 65,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        final base64Str = base64Encode(bytes);
        final mime = file.name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
        setState(() {
          widget.controller.text = 'data:$mime;base64,$base64Str';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถเลือกรูปภาพได้: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.controller.text.isNotEmpty;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'รูปภาพประกอบ (เลือกจากเครื่อง หรือใส่ URL)',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 8),
        if (hasImage) ...[
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 160,
                  width: double.infinity,
                  color: Colors.grey.shade100,
                  child: _buildImageWidget(widget.controller.text, height: 160),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  backgroundColor: Colors.black.withValues(alpha: 0.6),
                  radius: 18,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                    onPressed: () {
                      setState(() {
                        widget.controller.clear();
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        OutlinedButton.icon(
          onPressed: () => _pick(ImageSource.gallery),
          icon: const Icon(Icons.photo_library_outlined, size: 18),
          label: const Text('เลือกรูปภาพจากคลังภาพ (Gallery)'),
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryColor,
            side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => setState(() => _showUrlInput = !_showUrlInput),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              _showUrlInput ? 'ซ่อนช่องระบุ URL' : 'หรือวาง URL รูปภาพแทน',
              style: TextStyle(fontSize: 12, color: primaryColor, decoration: TextDecoration.underline),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        if (_showUrlInput) ...[
          const SizedBox(height: 6),
          TextFormField(
            controller: widget.controller,
            decoration: const InputDecoration(
              hintText: 'https://example.com/image.jpg',
              prefixIcon: Icon(Icons.link_rounded),
              isDense: true,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ],
    );
  }
}
