import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:achiver_app/services/teacher_resources_service.dart';
import '../services/auth_service.dart';
import '../services/teacher_profile_service.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: TeacherResourcesScreen(),
  ));
}

class TeacherResourcesScreen extends StatefulWidget {
  const TeacherResourcesScreen({super.key});

  @override
  State<TeacherResourcesScreen> createState() => _TeacherResourcesScreenState();
}

class _TeacherResourcesScreenState extends State<TeacherResourcesScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  bool _isGridView = false;
  bool _isLoading = false;
  Map<String, dynamic>? teacherData;
  String empid = "";
  bool isproLoading = true;
  final FirebaseResourceService _resourceService = FirebaseResourceService();
  final TeacherProfileService _profileService = TeacherProfileService();
  List<ResourceItem> _allResources = [];
  List<ResourceItem> _filteredResources = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    fetchTeacherProfile();
    print("Teacher from resources page 1 : ${empid}");
    // _loadResources();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchTeacherProfile() async {
    final String? teacherId = await AuthService.getUserId();
    if (teacherId == null) {
      setState(() {
        isproLoading = false;
      });
      return;
    }
    setState(() {
      empid = teacherId;
    });
    _loadResources(teacherId);
    // final profile = await _profileService.getTeacherProfile(teacherId);
    print("Teacher from resources page : ${teacherId}");
  }

  Future<void> _loadResources(String teacherId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final resources = await _resourceService.getAllResources(teacherId);
      setState(() {
        _allResources = resources;
        _filteredResources = resources;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load resources: $e');
    }
  }

  void _filterResources() {
    if (_searchQuery.isEmpty) {
      setState(() {
        _filteredResources = _allResources;
      });
    } else {
      setState(() {
        _filteredResources = _allResources
            .where((resource) =>
                resource.title
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                resource.description
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                resource.category
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()))
            .toList();
      });
    }
  }

  List<ResourceItem> _getResourcesByType(ResourceType type) {
    return _filteredResources
        .where((resource) => resource.type == type)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.indigo[900]!, Colors.indigo[50]!],
            stops: const [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchBar(),
              _buildTabBar(),
              Expanded(
                child: _isLoading
                    ? _buildLoadingWidget()
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildAllResourcesTab(),
                          _buildResourceTypeTab(ResourceType.video),
                          _buildResourceTypeTab(ResourceType.pdf),
                          _buildResourceTypeTab(ResourceType.word),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUploadDialog(),
        backgroundColor: Colors.indigo[700],
        icon: const Icon(Icons.cloud_upload),
        label: Text(
          'Upload Resource',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ).animate().scale(delay: 800.ms),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo[700]!),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading resources...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.indigo[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.school,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Teacher Resources',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${_allResources.length} resources available',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _loadResources(empid),
            icon: Icon(
              Icons.refresh,
              color: Colors.white,
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
            icon: Icon(
              _isGridView ? Icons.list : Icons.grid_view,
              color: Colors.white,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY();
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
          _filterResources();
        },
        decoration: InputDecoration(
          hintText: 'Search resources...',
          hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
          prefixIcon: Icon(Icons.search, color: Colors.indigo[700]),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
        style: GoogleFonts.poppins(),
      ),
    ).animate().fadeIn().slideY(delay: 200.ms);
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.indigo[700],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle:
            GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
        tabs: [
          Tab(text: 'All (${_filteredResources.length})'),
          Tab(
              text:
                  'Videos (${_getResourcesByType(ResourceType.video).length})'),
          Tab(text: 'PDFs (${_getResourcesByType(ResourceType.pdf).length})'),
          Tab(text: 'Docs (${_getResourcesByType(ResourceType.word).length})'),
        ],
      ),
    ).animate().fadeIn().slideY(delay: 400.ms);
  }

  Widget _buildAllResourcesTab() {
    if (_filteredResources.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      margin: const EdgeInsets.all(20),
      child: _isGridView
          ? _buildGridView(_filteredResources)
          : _buildListView(_filteredResources),
    );
  }

  Widget _buildResourceTypeTab(ResourceType type) {
    final resources = _getResourcesByType(type);

    if (resources.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      margin: const EdgeInsets.all(20),
      child:
          _isGridView ? _buildGridView(resources) : _buildListView(resources),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No resources found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try uploading some resources or adjusting your search',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(List<ResourceItem> resources) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: resources.length,
      itemBuilder: (context, index) {
        return _buildResourceCard(resources[index], index);
      },
    );
  }

  Widget _buildListView(List<ResourceItem> resources) {
    return ListView.builder(
      itemCount: resources.length,
      itemBuilder: (context, index) {
        return _buildResourceListTile(resources[index], index);
      },
    );
  }

  Widget _buildResourceCard(ResourceItem resource, int index) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.grey[50]!],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  image: DecorationImage(
                    image: NetworkImage(resource.thumbnail),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7)
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _getTypeColor(resource.type),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getTypeIcon(resource.type),
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, color: Colors.white),
                          onSelected: (value) =>
                              _handleMenuAction(value, resource),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 18),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete,
                                      size: 18, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete',
                                      style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        left: 8,
                        right: 8,
                        child: Text(
                          resource.title,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resource.description,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          resource.size,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _downloadResource(resource),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.indigo[700],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.download,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (100 * index).ms).scale();
  }

  Widget _buildResourceListTile(ResourceItem resource, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Colors.white, Colors.grey[50]!],
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(resource.thumbnail),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: _getTypeColor(resource.type).withValues(alpha: 0.8),
              ),
              child: Icon(
                _getTypeIcon(resource.type),
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          title: Text(
            resource.title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                resource.description,
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          _getTypeColor(resource.type).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      resource.category,
                      style: GoogleFonts.poppins(
                        color: _getTypeColor(resource.type),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    resource.size,
                    style: GoogleFonts.poppins(
                      color: Colors.grey[500],
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(resource.createdAt),
                    style: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.indigo[700],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.download, color: Colors.white),
                  onPressed: () => _downloadResource(resource),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) => _handleMenuAction(value, resource),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (100 * index).ms).slideX();
  }

  Color _getTypeColor(ResourceType type) {
    switch (type) {
      case ResourceType.video:
        return Colors.red[600]!;
      case ResourceType.pdf:
        return Colors.orange[600]!;
      case ResourceType.word:
        return Colors.blue[600]!;
    }
  }

  IconData _getTypeIcon(ResourceType type) {
    switch (type) {
      case ResourceType.video:
        return Icons.play_circle_filled;
      case ResourceType.pdf:
        return Icons.picture_as_pdf;
      case ResourceType.word:
        return Icons.description;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 30) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _downloadResource(ResourceItem resource) async {
    if (resource.downloadUrl == null) {
      _showErrorSnackBar('Download URL not available');
      return;
    }
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath =
          '${dir.path}/${resource.title}_${DateTime.now().millisecondsSinceEpoch}';
      final fileExtension =
          resource.downloadUrl!.split('.').last.split('?').first;
      final fullPath = '$filePath.$fileExtension';

      final dio = Dio();
      await dio.download(resource.downloadUrl!, fullPath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloaded to $fullPath'),
          backgroundColor: Colors.green,
        ),
      );

      // Optionally open the file
      await OpenFilex.open(fullPath);
    } catch (e) {
      _showErrorSnackBar('Failed to download: $e');
    }
  }

  void _handleMenuAction(String action, ResourceItem resource) {
    switch (action) {
      case 'edit':
        _showEditDialog(resource);
        break;
      case 'delete':
        _showDeleteConfirmation(resource);
        break;
    }
  }

  void _showEditDialog(ResourceItem resource) {
    final titleController = TextEditingController(text: resource.title);
    final descriptionController =
        TextEditingController(text: resource.description);
    final categoryController = TextEditingController(text: resource.category);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Edit Resource',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  labelStyle: GoogleFonts.poppins(),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                style: GoogleFonts.poppins(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: GoogleFonts.poppins(),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                style: GoogleFonts.poppins(),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: categoryController,
                decoration: InputDecoration(
                  labelText: 'Category',
                  labelStyle: GoogleFonts.poppins(),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                style: GoogleFonts.poppins(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () => _updateResource(
              resource,
              titleController.text,
              descriptionController.text,
              categoryController.text,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo[700],
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Update',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateResource(
    ResourceItem resource,
    String title,
    String description,
    String category,
  ) async {
    Navigator.pop(context);

    try {
      final updatedResource = resource.copyWith(
        title: title,
        description: description,
        category: category,
      );

      await _resourceService.updateResource(resource.id!, updatedResource);
      await _loadResources(empid);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Resource updated successfully',
              style: GoogleFonts.poppins()),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Failed to update resource: $e');
    }
  }

  void _showDeleteConfirmation(ResourceItem resource) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Resource',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "${resource.title}"? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () => _deleteResource(resource),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteResource(ResourceItem resource) async {
    Navigator.pop(context);

    try {
      await _resourceService.deleteResource(resource.id!, resource.downloadUrl);
      await _loadResources(empid);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Resource deleted successfully',
              style: GoogleFonts.poppins()),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Failed to delete resource: $e');
    }
  }

  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Upload Resource',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select the type of resource you want to upload',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildUploadOption(
                    Icons.videocam, 'Video', Colors.red, ResourceType.video),
                _buildUploadOption(Icons.picture_as_pdf, 'PDF', Colors.orange,
                    ResourceType.pdf),
                _buildUploadOption(Icons.description, 'Document', Colors.blue,
                    ResourceType.word),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadOption(
      IconData icon, String label, Color color, ResourceType type) {
    return GestureDetector(
      onTap: () => _uploadResource(type),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadResource(ResourceType type) async {
    Navigator.pop(context);

    try {
      _showUploadProgressDialog();

      ResourceItem? resource = await _resourceService.pickAndUploadFile(
        type: type,
        onProgress: (progress) {
          // Update progress in dialog
        },
      );

      Navigator.pop(context); // Close progress dialog

      if (resource != null) {
        _showResourceDetailsDialog(resource, type);
      }
    } catch (e) {
      Navigator.pop(context); // Close progress dialog
      _showErrorSnackBar('Failed to upload file: $e');
    }
  }

  void _showUploadProgressDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo[700]!),
            ),
            const SizedBox(height: 16),
            Text(
              'Uploading file...',
              style: GoogleFonts.poppins(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  void _showResourceDetailsDialog(ResourceItem resource, ResourceType type) {
    final titleController = TextEditingController(text: resource.title);
    final descriptionController =
        TextEditingController(text: resource.description);
    final categoryController = TextEditingController(text: resource.category);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Resource Details',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  labelStyle: GoogleFonts.poppins(),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                style: GoogleFonts.poppins(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: GoogleFonts.poppins(),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                style: GoogleFonts.poppins(),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: categoryController,
                decoration: InputDecoration(
                  labelText: 'Category',
                  labelStyle: GoogleFonts.poppins(),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                style: GoogleFonts.poppins(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () => _saveResource(
              resource,
              titleController.text,
              descriptionController.text,
              categoryController.text,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo[700],
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Save',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveResource(
    ResourceItem resource,
    String title,
    String description,
    String category,
  ) async {
    Navigator.pop(context);

    try {
      final finalResource = resource.copyWith(
        title: title,
        description: description,
        category: category,
      );

      await _resourceService.addResource(finalResource, null);
      await _loadResources(empid);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Resource uploaded successfully',
              style: GoogleFonts.poppins()),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Failed to save resource: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
