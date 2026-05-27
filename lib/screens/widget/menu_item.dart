// // screens/dashboard/widgets/menu_item.dart - PRECISION PROFESSIONAL DESIGN
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:myquran/screens/util/constants.dart';

// class MenuItem extends StatelessWidget {
//   final String title;
//   final String subtitle;
//   final IconData? icon;
//   final String? customImage;
//   final List<Color> gradient;
//   final VoidCallback onTap;

//   const MenuItem({
//     Key? key,
//     required this.title,
//     required this.subtitle,
//     this.icon,
//     this.customImage,
//     required this.gradient,
//     required this.onTap,
//   }) : super(key: key);

//   // ✅ CONSISTENT SPACING CONSTANTS
//   static const double _borderRadius = 24.0;

//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;
//     final isSmallScreen = size.width < 360;
//     final isMediumScreen = size.width >= 360 && size.width < 400;
    
//     return Container(
//       height: isSmallScreen ? 120 : (isMediumScreen ? 130 : 140),
//       width: double.infinity,
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: gradient,
//         ),
//         borderRadius: BorderRadius.circular(_borderRadius),
//         boxShadow: [
//           BoxShadow(
//             color: gradient[0].withOpacity(0.3),
//             blurRadius: 20,
//             offset: Offset(0, 10),
//             spreadRadius: 2,
//           ),
//         ],
//       ),
//       child: Material(
//         color: Colors.transparent,
//         borderRadius: BorderRadius.circular(_borderRadius),
//         child: InkWell(
//           onTap: () {
//             HapticFeedback.lightImpact();
//             onTap();
//           },
//           borderRadius: BorderRadius.circular(_borderRadius),
//           child: Stack(
//             children: [
//               // Decorative circles
//               Positioned(
//                 top: -20,
//                 right: -20,
//                 child: Container(
//                   width: 80,
//                   height: 80,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: Colors.white.withOpacity(0.05),
//                   ),
//                 ),
//               ),
//               Positioned(
//                 bottom: -15,
//                 left: -15,
//                 child: Container(
//                   width: 60,
//                   height: 60,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: Colors.white.withOpacity(0.03),
//                   ),
//                 ),
//               ),
              
//               // Content
//               Padding(
//                 padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           _buildTextContent(isSmallScreen, isMediumScreen),
//                           _buildButton(isSmallScreen),
//                         ],
//                       ),
//                     ),
//                     SizedBox(width: 12),
//                     _buildIcon(isSmallScreen, isMediumScreen),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTextContent(bool isSmallScreen, bool isMediumScreen) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Text(
//           title,
//           style: TextStyle(
//             fontSize: isSmallScreen ? 20 : (isMediumScreen ? 22 : 24),
//             fontWeight: FontWeight.bold,
//             color: Colors.white,
//             height: 1.1,
//             letterSpacing: 0.5,
//             shadows: [
//               Shadow(
//                 color: Colors.black.withOpacity(0.2),
//                 offset: Offset(0, 2),
//                 blurRadius: 4,
//               ),
//             ],
//           ),
//           maxLines: 1,
//           overflow: TextOverflow.ellipsis,
//         ),
//         SizedBox(height: 4),
//         Text(
//           subtitle,
//           style: TextStyle(
//             fontSize: isSmallScreen ? 12 : (isMediumScreen ? 13 : 14),
//             color: Colors.white.withOpacity(0.9),
//             fontWeight: FontWeight.w500,
//             letterSpacing: 0.2,
//             height: 1.3,
//           ),
//           maxLines: 2,
//           overflow: TextOverflow.ellipsis,
//         ),
//       ],
//     );
//   }

//   Widget _buildButton(bool isSmallScreen) {
//     return Container(
//       padding: EdgeInsets.symmetric(
//         horizontal: isSmallScreen ? 12 : 14,
//         vertical: isSmallScreen ? 6 : 8,
//       ),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.25),
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(
//           color: Colors.white.withOpacity(0.3),
//           width: 1.5,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 8,
//             offset: Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(
//             'Mulai',
//             style: TextStyle(
//               fontSize: isSmallScreen ? 11.5 : 13,
//               fontWeight: FontWeight.w600,
//               color: Colors.white,
//               letterSpacing: 0.3,
//             ),
//           ),
//           SizedBox(width: 6),
//           Icon(
//             Icons.arrow_forward_rounded,
//             color: Colors.white,
//             size: isSmallScreen ? 14 : 16,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildIcon(bool isSmallScreen, bool isMediumScreen) {
//     final iconSize = isSmallScreen ? 64 : (isMediumScreen ? 70 : 76);
    
//     return Container(
//       width: iconSize.toDouble(),
//       height: iconSize.toDouble(),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.2),
//         borderRadius: BorderRadius.circular(18),
//         border: Border.all(
//           color: Colors.white.withOpacity(0.3),
//           width: 2,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 12,
//             offset: Offset(0, 4),
//           ),
//         ],
//       ),
//       child: customImage != null
//           ? Padding(
//               padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
//               child: Image.asset(
//                 customImage!,
//                 fit: BoxFit.contain,
//                 errorBuilder: (context, error, stackTrace) {
//                   return Center(
//                     child: Icon(
//                       Icons.image_not_supported,
//                       color: Colors.white.withOpacity(0.6),
//                       size: isSmallScreen ? 32 : 36,
//                     ),
//                   );
//                 },
//               ),
//             )
//           : Center(
//               child: Icon(
//                 icon,
//                 color: Colors.white,
//                 size: isSmallScreen ? 32 : (isMediumScreen ? 36 : 40),
//               ),
//             ),
//     );
//   }
// }