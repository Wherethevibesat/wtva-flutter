import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_bootstrap.dart';
import 'supabase_data.dart';

class VenueImageService {
  VenueImageService._();
  static final VenueImageService instance = VenueImageService._();

  static const _bucket = 'venue-images';
  static const _maxBytes = 5 * 1024 * 1024;

  Future<XFile?> pickImage() async {
    final picker = ImagePicker();
    return picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
  }

  Future<String?> uploadEventImage({
    required String ownerId,
    required XFile file,
  }) async {
    return uploadForOwner(ownerId: ownerId, file: file, prefix: 'event');
  }

  Future<String?> uploadForOwner({
    required String ownerId,
    required XFile file,
    String prefix = 'venue',
  }) async {
    if (!SupabaseData.syncAuth) return null;
    final client = SupabaseBootstrap.client;
    if (client == null) return null;

    final bytes = await file.readAsBytes();
    if (bytes.isEmpty || bytes.length > _maxBytes) return null;

    final ext = _extForName(file.name);
    final path = '$ownerId/${prefix}_${DateTime.now().millisecondsSinceEpoch}.$ext';

    await client.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: _mimeForExt(ext),
            upsert: true,
          ),
        );

    return client.storage.from(_bucket).getPublicUrl(path);
  }

  String _extForName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'png';
    if (lower.endsWith('.webp')) return 'webp';
    return 'jpg';
  }

  String _mimeForExt(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}
