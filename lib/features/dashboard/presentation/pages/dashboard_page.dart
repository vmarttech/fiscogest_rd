import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_radius.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  static const String routeName = 'dashboard';

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);

    // ─── Solo rediseño visual PC; en móvil se mantiene usable ───
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isMobile),
              const SizedBox(height: 20),
              _buildWelcomeBanner(isMobile),
              const SizedBox(height: 20),
              _buildSmallKpis(isMobile),
              const SizedBox(height: 20),
              _buildActionCards(context, isMobile),
              const SizedBox(height: 24),
              if (isMobile) ...[
                _buildExcepcionesCard(),
                const SizedBox(height: 16),
                _buildAlertasCard(),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildExcepcionesCard()),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: _buildAlertasCard()),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────
  Widget _buildHeader(bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style: AppTypography.h2.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Resumen operativo en tiempo real',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        if (!isMobile)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: AppRadius.allM,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text('Hoy', style: AppTypography.labelMedium.copyWith(color: AppColors.textPrimary)),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textSecondary),
              ],
            ),
          ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // BANNER BIENVENIDA (estilo adjunto)
  // ─────────────────────────────────────────────
  Widget _buildWelcomeBanner(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 18 : 28,
        vertical: isMobile ? 20 : 26,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.allL,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F766E), // Teal-700
            Color(0xFF115E59), // Teal-800
          ],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Bienvenido de nuevo! 👋',
                  style: AppTypography.h3.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 18 : 22,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Esto es lo que está pasando en tu negocio hoy.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.white.withValues(alpha: 0.85)),
                    const SizedBox(width: 6),
                    Text(
                      _fechaHoy(),
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!isMobile)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.white.withValues(alpha: 0.25)),
              ),
              child: Text(
                'FiscoGest RD',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _fechaHoy() {
    final now = DateTime.now();
    const dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    const meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    return '${dias[now.weekday - 1]}, ${now.day} de ${meses[now.month - 1]} ${now.year}';
  }

  // ─────────────────────────────────────────────
  // KPIs PEQUEÑOS (fila estilo adjunto)
  // ─────────────────────────────────────────────
  Widget _buildSmallKpis(bool isMobile) {
    final kpis = [
      const _SmallKpi(title: 'VENTAS HOY', value: '\$18,392', icon: Icons.point_of_sale_outlined, bg: Color(0xFFECFDF5), iconColor: AppColors.success),
      const _SmallKpi(title: 'ALERTAS', value: '12', icon: Icons.warning_amber_rounded, bg: Color(0xFFFFF7ED), iconColor: AppColors.warning),
      const _SmallKpi(title: 'VALOR STOCK', value: '\$2.8M', icon: Icons.account_balance_wallet_outlined, bg: Color(0xFFFEF2F2), iconColor: AppColors.error),
      const _SmallKpi(title: 'FILL RATE', value: '92.6%', icon: Icons.trending_up_rounded, bg: Color(0xFFEFF6FF), iconColor: AppColors.info),
      const _SmallKpi(title: 'CLIENTES', value: '—', icon: Icons.people_outline, bg: Color(0xFFF5F3FF), iconColor: Color(0xFF7C3AED)),
      const _SmallKpi(title: 'PRODUCTOS', value: '—', icon: Icons.inventory_2_outlined, bg: Color(0xFFECFEFF), iconColor: AppColors.primary),
      const _SmallKpi(title: 'COMPRAS', value: '—', icon: Icons.shopping_cart_outlined, bg: Color(0xFFF0FDF4), iconColor: AppColors.success),
      const _SmallKpi(title: 'PENDIENTES', value: '—', icon: Icons.pending_actions_outlined, bg: Color(0xFFFDF4FF), iconColor: Color(0xFFA855F7)),
    ];

    if (isMobile) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.6,
        children: kpis.map((k) => _SmallKpiCard(data: k)).toList(),
      );
    }

    return Row(
      children: kpis
          .map(
            (k) => Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _SmallKpiCard(data: k),
              ),
            ),
          )
          .toList(),
    );
  }

  // ─────────────────────────────────────────────
  // 3 TARJETAS GRANDES (la violeta = carrusel)
  // ─────────────────────────────────────────────
  Widget _buildActionCards(BuildContext context, bool isMobile) {
    final cards = [
      _ActionCardData(
        title: 'Nueva Venta',
        subtitle: 'Facturar o registrar una venta',
        icon: Icons.point_of_sale_rounded,
        gradient: const [Color(0xFF0F766E), Color(0xFF0D9488)],
        onTap: () => context.go('/ventas'),
      ),
      _ActionCardData(
        title: 'Nueva Compra',
        subtitle: 'Registrar compra a proveedor',
        icon: Icons.shopping_cart_rounded,
        gradient: const [Color(0xFF2563EB), Color(0xFF3B82F6)],
        onTap: () => context.go('/compras/registrar'),
      ),
      // ─── TARJETA VIOLETA = CARRUSEL ───
      const _ActionCardData(
        title: 'Carrusel',
        subtitle: 'Promociones y avisos',
        icon: Icons.view_carousel_rounded,
        gradient: [Color(0xFF7C3AED), Color(0xFFA855F7)],
        onTap: null,
        isCarousel: true,
      ),
    ];

    if (isMobile) {
      return Column(
        children: cards
            .map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: c.isCarousel ? _CarouselCard(data: c) : _ActionCard(data: c),
              ),
            )
            .toList(),
      );
    }

    return Row(
      children: cards
          .map(
            (c) => Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: c.isCarousel ? _CarouselCard(data: c) : _ActionCard(data: c),
              ),
            ),
          )
          .toList(),
    );
  }

  // ─────────────────────────────────────────────
  // EXCEPCIONES (Recent)
  // ─────────────────────────────────────────────
  Widget _buildExcepcionesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.allL,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.inventory_2_outlined, size: 18, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Excepciones de Inventario',
                    style: AppTypography.h4.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Ver todo →',
                  style: AppTypography.labelMedium.copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('Producto', style: _headerStyle)),
                Expanded(flex: 2, child: Text('Estado', style: _headerStyle)),
                Expanded(flex: 2, child: Text('Stock', style: _headerStyle)),
                Expanded(flex: 2, child: Text('Riesgo', style: _headerStyle)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const _ExceptionRow(name: 'Mascarilla quirúrgica 50-pack', status: 'Crítico', statusColor: AppColors.error, stock: '120', risk: '\$1,240'),
          const _ExceptionRow(name: 'Suero IV 1000ml', status: 'Crítico', statusColor: AppColors.error, stock: '35', risk: '\$875'),
          const _ExceptionRow(name: 'Paracetamol 500mg', status: 'Exceso', statusColor: AppColors.warning, stock: '12,750', risk: '\$2,805'),
          const _ExceptionRow(name: 'Guantes de nitrilo 100-pack', status: 'Crítico', statusColor: AppColors.error, stock: '80', risk: '\$960'),
          const _ExceptionRow(name: 'Cilindro de oxígeno (E)', status: 'Exceso', statusColor: AppColors.warning, stock: '45', risk: '\$4,500'),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // ALERTAS (Top)
  // ─────────────────────────────────────────────
  Widget _buildAlertasCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.allL,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.notifications_active_outlined, size: 18, color: AppColors.info),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Alertas Prioritarias',
                    style: AppTypography.h4.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Ver todo →',
                  style: AppTypography.labelMedium.copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _AlertItem(
            title: 'Stock crítico: Mascarillas quirúrgicas',
            subtitle: 'Solo 120 unidades (mínimo 500)',
            level: AlertLevel.critical,
          ),
          const _AlertItem(
            title: 'Reorden recomendado: 12 SKUs',
            subtitle: 'Productos por debajo del punto de reorden',
            level: AlertLevel.warning,
          ),
          const _AlertItem(
            title: 'Discrepancia de conteo',
            subtitle: '2 productos con diferencia en inventario físico',
            level: AlertLevel.info,
          ),
          const _AlertItem(
            title: 'Transferencia pendiente',
            subtitle: 'Almacén Este → Tienda Norte',
            level: AlertLevel.info,
          ),
        ],
      ),
    );
  }

  TextStyle get _headerStyle => AppTypography.labelSmall.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      );
}

// ─────────────────────────────────────────────
// SMALL KPI
// ─────────────────────────────────────────────
class _SmallKpi {
  const _SmallKpi({
    required this.title,
    required this.value,
    required this.icon,
    required this.bg,
    required this.iconColor,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color bg;
  final Color iconColor;
}

class _SmallKpiCard extends StatelessWidget {
  const _SmallKpiCard({required this.data});
  final _SmallKpi data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: data.bg,
        borderRadius: AppRadius.allL,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, size: 18, color: data.iconColor),
          ),
          const Spacer(),
          Text(
            data.value,
            style: AppTypography.h4.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.title,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ACTION CARDS
// ─────────────────────────────────────────────
class _ActionCardData {
  const _ActionCardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    this.onTap,
    this.isCarousel = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback? onTap;
  final bool isCarousel;
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.data});
  final _ActionCardData data;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: AppRadius.allL,
      child: InkWell(
        onTap: data.onTap,
        borderRadius: AppRadius.allL,
        child: Container(
          height: 140,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: AppRadius.allL,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: data.gradient,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(data.icon, color: AppColors.white, size: 22),
                  ),
                  Icon(Icons.arrow_outward_rounded, color: AppColors.white.withValues(alpha: 0.8), size: 20),
                ],
              ),
              const Spacer(),
              Text(
                data.title,
                style: AppTypography.h4.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                data.subtitle,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CARRUSEL (tarjeta violeta)
// ── Reemplaza el contenido de PageView por tu carrusel real ──
// ─────────────────────────────────────────────
class _CarouselCard extends StatefulWidget {
  const _CarouselCard({required this.data});
  final _ActionCardData data;

  @override
  State<_CarouselCard> createState() => _CarouselCardState();
}

class _CarouselCardState extends State<_CarouselCard> {
  final _controller = PageController();
  int _page = 0;

  // ── Slides de ejemplo (sustituye por tu carrusel) ──
  final _slides = const [
    _Slide(
      title: 'Promoción activa',
      subtitle: 'Descuentos de temporada en productos seleccionados',
      icon: Icons.local_offer_outlined,
    ),
    _Slide(
      title: 'Stock bajo',
      subtitle: '12 SKUs requieren reorden urgente',
      icon: Icons.warning_amber_rounded,
    ),
    _Slide(
      title: 'Meta del mes',
      subtitle: 'Vas al 78% de la meta de ventas',
      icon: Icons.flag_outlined,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        borderRadius: AppRadius.allL,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.data.gradient,
        ),
      ),
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: _slides.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) {
              final s = _slides[i];
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(s.icon, color: AppColors.white, size: 22),
                        ),
                        Icon(Icons.arrow_outward_rounded, color: AppColors.white.withValues(alpha: 0.8), size: 20),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      s.title,
                      style: AppTypography.h4.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.white.withValues(alpha: 0.9),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
          // Indicadores
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _page == i ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: _page == i ? 1 : 0.4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Slide {
  const _Slide({required this.title, required this.subtitle, required this.icon});
  final String title;
  final String subtitle;
  final IconData icon;
}

// ─────────────────────────────────────────────
// ALERTAS / EXCEPCIONES (sin cambios de lógica)
// ─────────────────────────────────────────────
enum AlertLevel { critical, warning, info }

class _AlertItem extends StatelessWidget {
  const _AlertItem({
    required this.title,
    required this.subtitle,
    required this.level,
  });

  final String title;
  final String subtitle;
  final AlertLevel level;

  @override
  Widget build(BuildContext context) {
    final Color color = switch (level) {
      AlertLevel.critical => AppColors.error,
      AlertLevel.warning => AppColors.warning,
      AlertLevel.info => AppColors.info,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExceptionRow extends StatelessWidget {
  const _ExceptionRow({
    required this.name,
    required this.status,
    required this.statusColor,
    required this.stock,
    required this.risk,
  });

  final String name;
  final String status;
  final Color statusColor;
  final String stock;
  final String risk;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              name,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                status,
                style: AppTypography.labelSmall.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              stock,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              risk,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
