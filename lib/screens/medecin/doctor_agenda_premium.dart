import 'package:flutter/material.dart';
import '../../core/theme/doctor_theme.dart';
import '../../widgets/doctor_premium_widgets.dart';

class DoctorAgendaPremium extends StatefulWidget {
  const DoctorAgendaPremium({super.key});

  @override
  State<DoctorAgendaPremium> createState() => _DoctorAgendaPremiumState();
}

class _DoctorAgendaPremiumState extends State<DoctorAgendaPremium> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeaderDoctorUI(
          title: 'Agenda',
          subtitle: 'Gérez vos rendez-vous et consultations',
        ),
        const SizedBox(height: DoctorTheme.spacing16),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildCalendar(),
            ),
            const SizedBox(width: DoctorTheme.spacing16),
            Expanded(
              flex: 1,
              child: _buildDaySchedule(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCalendar() {
    return DoctorCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Calendrier',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: () {
                      setState(() => _selectedDate = DateTime(
                        _selectedDate.year,
                        _selectedDate.month - 1,
                      ));
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: () {
                      setState(() => _selectedDate = DateTime(
                        _selectedDate.year,
                        _selectedDate.month + 1,
                      ));
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: DoctorTheme.spacing16),
          _buildSimpleCalendar(),
          const SizedBox(height: DoctorTheme.spacing16),
          const Divider(),
          const SizedBox(height: DoctorTheme.spacing16),
          _buildUpcomingAppointments(),
        ],
      ),
    );
  }

  Widget _buildSimpleCalendar() {
    final firstDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final lastDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final weekdayStart = firstDayOfMonth.weekday;

    final weekDays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

    return Column(
      children: [
        // Month year
        Text(
          '${_getMonthName(_selectedDate.month)} ${_selectedDate.year}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: DoctorTheme.spacing12),
        // Weekday headers
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: weekDays.map((day) {
            return Center(
              child: Text(
                day,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: DoctorTheme.textSecondary,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: DoctorTheme.spacing8),
        // Days
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            // Empty cells before first day
            ...List.generate(weekdayStart - 1, (_) => const SizedBox()),
            // Days of month
            ...List.generate(daysInMonth, (index) {
              final day = index + 1;
              final isToday = day == DateTime.now().day &&
                  _selectedDate.month == DateTime.now().month &&
                  _selectedDate.year == DateTime.now().year;

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedDate = DateTime(
                    _selectedDate.year,
                    _selectedDate.month,
                    day,
                  ));
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: isToday ? DoctorTheme.blueVioletGradient : null,
                    color: isToday ? null : Colors.transparent,
                    borderRadius: DoctorTheme.radiusSmall,
                    border: !isToday
                        ? Border.all(
                            color: day == _selectedDate.day
                                ? DoctorTheme.primaryBlue
                                : Colors.transparent,
                          )
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      day.toString(),
                      style: TextStyle(
                        color: isToday ? Colors.white : DoctorTheme.textPrimary,
                        fontWeight: isToday || day == _selectedDate.day
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildUpcomingAppointments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rendez-vous à venir',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: DoctorTheme.spacing12),
        _buildAppointmentItem('Ahmed Ibrahim', '10:00 - 10:30', DoctorTheme.successGreen),
        const SizedBox(height: DoctorTheme.spacing8),
        _buildAppointmentItem('Sarah Mohamed', '11:00 - 11:30', DoctorTheme.infoBlue),
        const SizedBox(height: DoctorTheme.spacing8),
        _buildAppointmentItem('Hassan Ali', '14:00 - 14:30', DoctorTheme.accentOrange),
      ],
    );
  }

  Widget _buildAppointmentItem(String name, String time, Color color) {
    return Container(
      padding: const EdgeInsets.all(DoctorTheme.spacing12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: DoctorTheme.radiusSmall,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: DoctorTheme.textPrimary,
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              fontSize: 12,
              color: DoctorTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySchedule() {
    return DoctorCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Horaire du jour',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: DoctorTheme.spacing16),
          _buildTimeSlot('08:00', 'Début de journée'),
          const SizedBox(height: DoctorTheme.spacing12),
          _buildTimeSlot('12:00', 'Pause déjeuner'),
          const SizedBox(height: DoctorTheme.spacing12),
          _buildTimeSlot('18:00', 'Fin de journée'),
          const SizedBox(height: DoctorTheme.spacing16),
          const Divider(),
          const SizedBox(height: DoctorTheme.spacing16),
          DoctorButton(
            label: 'Ajouter rendez-vous',
            onPressed: () {},
            icon: Icons.add_rounded,
            gradient: DoctorTheme.greenBlueGradient,
            width: double.infinity,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlot(String time, String label) {
    return Row(
      children: [
        Text(
          time,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: DoctorTheme.textPrimary,
          ),
        ),
        const SizedBox(width: DoctorTheme.spacing8),
        Expanded(
          child: Container(
            height: 2,
            color: DoctorTheme.dividerColor,
          ),
        ),
        const SizedBox(width: DoctorTheme.spacing8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: DoctorTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return months[month - 1];
  }
}
