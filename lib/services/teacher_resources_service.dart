import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:achiver_app/services/auth_service.dart';
import 'package:achiver_app/services/teacher_profile_service.dart';

enum ResourceType { video, pdf, word }

class ResourceItem {
  final String? id;
  final String title;
  final ResourceType type;
  final String size;
  final String description;
  final String category;
  final String? duration;
  final String? pages;
  final String thumbnail;
  final String? downloadUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String teacherId;
  final String teacherName;
  final String teacherEmail;

  ResourceItem({
    this.id,
    required this.title,
    required this.type,
    required this.size,
    required this.description,
    required this.category,
    required this.thumbnail,
    this.duration,
    this.pages,
    this.downloadUrl,
    required this.teacherId,
    required this.teacherName,
    required this.teacherEmail,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'type': type.toString().split('.').last,
      'size': size,
      'description': description,
      'category': category,
      'duration': duration,
      'pages': pages,
      'thumbnail': thumbnail,
      'downloadUrl': downloadUrl,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'teacherEmail': teacherEmail,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ResourceItem.fromJson(Map<String, dynamic> json, String id) {
    return ResourceItem(
      id: id,
      title: json['title'] ?? '',
      type: ResourceType.values.firstWhere(
        (e) => e.toString().split('.').last == (json['type'] ?? 'pdf'),
        orElse: () => ResourceType.pdf,
      ),
      size: json['size'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      duration: json['duration'],
      pages: json['pages'],
      thumbnail: json['thumbnail'] ?? '',
      downloadUrl: json['downloadUrl'],
      teacherId: json['teacherId'] ?? '',
      teacherName: json['teacherName'] ?? '',
      teacherEmail: json['teacherEmail'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  ResourceItem copyWith({
    String? id,
    String? title,
    ResourceType? type,
    String? size,
    String? description,
    String? category,
    String? duration,
    String? pages,
    String? thumbnail,
    String? downloadUrl,
    String? teacherId,
    String? teacherName,
    String? teacherEmail,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ResourceItem(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      size: size ?? this.size,
      description: description ?? this.description,
      category: category ?? this.category,
      duration: duration ?? this.duration,
      pages: pages ?? this.pages,
      thumbnail: thumbnail ?? this.thumbnail,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      teacherEmail: teacherEmail ?? this.teacherEmail,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class FirebaseResourceService {
  static const String _collectionName = 'teacher_resources';
  static const String _storagePath = 'resources';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Get collection reference
  CollectionReference get _collection => _firestore.collection(_collectionName);

  // Upload file to Firebase Storage
  Future<String> _uploadFile(
      File file, String fileName, ResourceType type) async {
    try {
      String folder = _getStorageFolder(type);
      String filePath = '$_storagePath/$folder/$fileName';

      Reference ref = _storage.ref().child(filePath);
      UploadTask uploadTask = ref.putFile(file);

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  // Get storage folder based on resource type
  String _getStorageFolder(ResourceType type) {
    switch (type) {
      case ResourceType.video:
        return 'videos';
      case ResourceType.pdf:
        return 'pdfs';
      case ResourceType.word:
        return 'documents';
    }
  }

  // Add new resource
  Future<String> addResource(ResourceItem resource, File? file) async {
    try {
      final String? teacherId = await AuthService.getUserId();
      if (teacherId == null) throw Exception('No user logged in');
      final teacherData =
          await TeacherProfileService().getTeacherProfile(teacherId);
      final teacherName = teacherData?['name'] ?? '';
      final teacherEmail = teacherData?['email'] ?? '';

      String? downloadUrl;
      if (file != null) {
        String fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${resource.title}';
        downloadUrl = await _uploadFile(file, fileName, resource.type);
      }

      ResourceItem resourceWithTeacher = resource.copyWith(
        downloadUrl: downloadUrl,
        teacherId: teacherId,
        teacherName: teacherName,
        teacherEmail: teacherEmail,
        updatedAt: DateTime.now(),
      );

      DocumentReference docRef =
          await _collection.add(resourceWithTeacher.toJson());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add resource: $e');
    }
  }

  // Get all resources
  Future<List<ResourceItem>> getAllResources(String teacher) async {
    try {
      print('Fetching resources for teacherId: $teacher');
      QuerySnapshot querySnapshot =
          await _collection.where('teacherId', isEqualTo: teacher).get();
      return querySnapshot.docs
          .map((doc) =>
              ResourceItem.fromJson(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get resources: $e');
    }
  }

  // Get resources by type
  Future<List<ResourceItem>> getResourcesByType(ResourceType type) async {
    try {
      QuerySnapshot querySnapshot = await _collection
          .where('type', isEqualTo: type.toString().split('.').last)
          .get();

      return querySnapshot.docs
          .map((doc) =>
              ResourceItem.fromJson(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get resources by type: $e');
    }
  }

  // Get resources by category
  Future<List<ResourceItem>> getResourcesByCategory(String category) async {
    try {
      QuerySnapshot querySnapshot =
          await _collection.where('category', isEqualTo: category).get();

      return querySnapshot.docs
          .map((doc) =>
              ResourceItem.fromJson(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get resources by category: $e');
    }
  }

  // Search resources
  Future<List<ResourceItem>> searchResources(String query) async {
    try {
      // Note: Firestore doesn't support full-text search natively
      // This is a basic implementation. For better search, consider using Algolia or ElasticSearch
      QuerySnapshot querySnapshot = await _collection.orderBy('title').startAt(
          [query.toLowerCase()]).endAt([query.toLowerCase() + '\uf8ff']).get();

      return querySnapshot.docs
          .map((doc) =>
              ResourceItem.fromJson(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to search resources: $e');
    }
  }

  // Update resource
  Future<void> updateResource(String id, ResourceItem resource) async {
    try {
      ResourceItem updatedResource = resource.copyWith(
        id: id,
        updatedAt: DateTime.now(),
      );

      await _collection.doc(id).update(updatedResource.toJson());
    } catch (e) {
      throw Exception('Failed to update resource: $e');
    }
  }

  // Delete resource
  Future<void> deleteResource(String id, String? downloadUrl) async {
    try {
      // Delete file from storage if exists
      if (downloadUrl != null) {
        try {
          Reference ref = _storage.refFromURL(downloadUrl);
          await ref.delete();
        } catch (e) {
          print('Warning: Could not delete file from storage: $e');
        }
      }

      // Delete document from Firestore
      await _collection.doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete resource: $e');
    }
  }

  // Get real-time resources stream
  Stream<List<ResourceItem>> getResourcesStream() {
    return _collection.snapshots().map((snapshot) => snapshot.docs
        .map((doc) =>
            ResourceItem.fromJson(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  // Get real-time resources stream by type
  Stream<List<ResourceItem>> getResourcesStreamByType(ResourceType type) {
    return _collection
        .where('type', isEqualTo: type.toString().split('.').last)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ResourceItem.fromJson(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Upload with progress tracking
  Future<String> uploadFileWithProgress({
    required File file,
    required String fileName,
    required ResourceType type,
    Function(double)? onProgress,
  }) async {
    try {
      String folder = _getStorageFolder(type);
      String filePath = '$_storagePath/$folder/$fileName';

      Reference ref = _storage.ref().child(filePath);
      UploadTask uploadTask = ref.putFile(file);

      // Listen to upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress?.call(progress);
      });

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  // Pick and upload file
  Future<ResourceItem?> pickAndUploadFile({
    required ResourceType type,
    Function(double)? onProgress,
  }) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _getAllowedExtensions(type),
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String fileName = result.files.single.name;
        int fileSize = result.files.single.size;

        String downloadUrl = await uploadFileWithProgress(
          file: file,
          fileName: fileName,
          type: type,
          onProgress: onProgress,
        );

        // Create resource item with basic info
        return ResourceItem(
          title: fileName.split('.').first,
          type: type,
          size: _formatFileSize(fileSize),
          description: 'Uploaded ${type.toString().split('.').last}',
          category: _getDefaultCategory(type),
          thumbnail: _getDefaultThumbnail(type),
          downloadUrl: downloadUrl,
          teacherId: '',
          teacherName: '',
          teacherEmail: '',
        );
      }

      return null;
    } catch (e) {
      throw Exception('Failed to pick and upload file: $e');
    }
  }

  // Get allowed extensions for file picker
  List<String> _getAllowedExtensions(ResourceType type) {
    switch (type) {
      case ResourceType.video:
        return ['mp4', 'avi', 'mov', 'wmv', 'flv', 'webm'];
      case ResourceType.pdf:
        return ['pdf'];
      case ResourceType.word:
        return ['doc', 'docx', 'txt', 'rtf'];
    }
  }

  // Format file size
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1073741824) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    return '${(bytes / 1073741824).toStringAsFixed(1)} GB';
  }

  // Get default category based on type
  String _getDefaultCategory(ResourceType type) {
    switch (type) {
      case ResourceType.video:
        return 'Educational Videos';
      case ResourceType.pdf:
        return 'Documents';
      case ResourceType.word:
        return 'Templates';
    }
  }

  // Get default thumbnail based on type
  String _getDefaultThumbnail(ResourceType type) {
    switch (type) {
      case ResourceType.video:
        return 'https://images.unsplash.com/photo-1635070041078-e363dbe005cb?w=400';
      case ResourceType.pdf:
        return 'https://images.unsplash.com/photo-1554224155-6726b3ff858f?w=400';
      case ResourceType.word:
        return 'https://images.unsplash.com/photo-1586281380349-632531db7ed4?w=400';
    }
  }

  // Get resource statistics
  Future<Map<String, int>> getResourceStatistics() async {
    try {
      QuerySnapshot allResources = await _collection.get();

      Map<String, int> stats = {
        'total': allResources.docs.length,
        'videos': 0,
        'pdfs': 0,
        'docs': 0,
      };

      for (var doc in allResources.docs) {
        String type = (doc.data() as Map<String, dynamic>)['type'] ?? '';
        switch (type) {
          case 'video':
            stats['videos'] = (stats['videos'] ?? 0) + 1;
            break;
          case 'pdf':
            stats['pdfs'] = (stats['pdfs'] ?? 0) + 1;
            break;
          case 'word':
            stats['docs'] = (stats['docs'] ?? 0) + 1;
            break;
        }
      }

      return stats;
    } catch (e) {
      throw Exception('Failed to get statistics: $e');
    }
  }
}
