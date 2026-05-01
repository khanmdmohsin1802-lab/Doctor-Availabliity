import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:curasync/config/theme.dart';
import 'package:curasync/providers/auth_provider.dart';
import 'package:curasync/services/api_service.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  int _selectedIndex = 0;
  String _searchQuery = '';
  String _selectedSpecialty = 'All Specialties';
  
  List<dynamic> _doctors = [];
  bool _isLoading = true;
  String? _error;

  static const List<String> _specialties = [
    'All Specialties',
    'General Physician',
    'Cardiologist',
    'Dermatologist',
    'Pediatrician',
    'Orthopedic',
  ];

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  Future<void> _fetchDoctors() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      final response = await ApiService.getDoctors(
        token: auth.token!,
        search: _searchQuery,
        specialty: _selectedSpecialty == 'All Specialties' ? null : _selectedSpecialty,
      );

      if (response['success'] == true) {
        setState(() {
          _doctors = response['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Failed to load doctors';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    // Debounce this in a real app, but for now we'll just fetch immediately or on submit.
  }

  void _onSpecialtySelected(String specialty) {
    setState(() => _selectedSpecialty = specialty);
    _fetchDoctors();
  }

  Future<void> _joinWaitlist(String doctorId) async {
    final auth = context.read<AuthProvider>();
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final res = await ApiService.joinQueue(
        token: auth.token!,
        doctorId: doctorId,
        reasonForVisit: 'General Consultation',
      );
      
      if (!mounted) return;
      Navigator.pop(context); // Remove loading dialog
      
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully joined the waitlist!'),
            backgroundColor: Colors.green,
          ),
        );
        // We could navigate to the Queue tab here
        setState(() => _selectedIndex = 1);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Failed to join waitlist'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network error.'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchDoctors,
                color: AppTheme.primaryBlue,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ─── Title & Subtitle ───
                      Text(
                        'Find your specialist.',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 32,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Access world-class clinical expertise from\nthe comfort of your home.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                              height: 1.5,
                              fontSize: 15,
                            ),
                      ),
                      const SizedBox(height: 24),

                      // ─── Search Bar ───
                      _buildSearchBar(),
                      const SizedBox(height: 24),

                      // ─── Specialty Tabs ───
                      _buildSpecialtyTabs(),
                      const SizedBox(height: 32),

                      // ─── Doctor List ───
                      _buildDoctorList(),
                      
                      const SizedBox(height: 40), // Bottom padding
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: AppTheme.primaryBlue),
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          Text(
            'CuraSync',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w700,
                ),
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
            child: const Icon(Icons.person, color: AppTheme.primaryBlue, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.inputFill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        onSubmitted: (val) {
          _onSearchChanged(val);
          _fetchDoctors();
        },
        decoration: InputDecoration(
          hintText: 'Search by doctor name, specialty',
          hintStyle: const TextStyle(color: AppTheme.textHint, fontSize: 15),
          prefixIcon: const Icon(Icons.search, color: AppTheme.textHint),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSpecialtyTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _specialties.map((specialty) {
          final isSelected = _selectedSpecialty == specialty;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => _onSpecialtySelected(specialty),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryBlue : AppTheme.inputFill,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  specialty,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDoctorList() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: AppTheme.error, size: 40),
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: AppTheme.error)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchDoctors,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_doctors.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: Text(
            'No doctors found.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _doctors.length,
      separatorBuilder: (context, index) => const SizedBox(height: 20),
      itemBuilder: (context, index) {
        final doc = _doctors[index];
        return _buildDoctorCard(doc);
      },
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doctor) {
    final name = doctor['name'] ?? 'Unknown Doctor';
    final specialty = doctor['specialty'] ?? 'General';
    final isAccepting = doctor['isAcceptingPatients'] == true;
    
    // In a real app we'd determine if they are in consultation vs available
    // Here we'll simulate it based on isAccepting
    final statusText = isAccepting ? 'AVAILABLE NOW' : 'IN CONSULTATION';
    final statusColor = isAccepting ? Colors.green : Colors.orange;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with status dot
              Stack(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, size: 40, color: AppTheme.primaryBlue),
                  ),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isAccepting ? 'TOP RATED' : 'EXPERT',
                            style: const TextStyle(
                              color: AppTheme.primaryBlue,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Icon(Icons.favorite_border, color: AppTheme.textHint, size: 20),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      specialty,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Action Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isAccepting ? Icons.check_circle : Icons.hourglass_top,
                    color: statusColor,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () => _joinWaitlist(doctor['_id']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAccepting ? AppTheme.primaryBlue : AppTheme.inputFill,
                  foregroundColor: isAccepting ? Colors.white : AppTheme.primaryBlue,
                  elevation: 0,
                  minimumSize: const Size(120, 48), // Override global infinite width
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isAccepting ? 'Book Now' : 'Join Waitlist',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_filled, 'HOME'),
              _buildNavItem(1, Icons.people_alt, 'QUEUE'),
              _buildNavItem(2, Icons.history, 'HISTORY'),
              _buildNavItem(3, Icons.person, 'PROFILE'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? AppTheme.primaryBlue : AppTheme.textHint;
    
    return GestureDetector(
      onTap: () {
        if (index == 0) return; // Already here
        setState(() => _selectedIndex = index);
        // Implement navigation to other tabs later
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
