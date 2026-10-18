import 'package:flutter/material.dart';
import 'brand.dart';

class TreasuryHeader extends StatelessWidget implements PreferredSizeWidget {
  const TreasuryHeader({super.key,required this.title,this.overline='TESORERÍA',this.busy=false});
  final String title,overline;
  final bool busy;
  @override Size get preferredSize=>const Size.fromHeight(90);
  @override Widget build(BuildContext context){
    final c=Theme.of(context).colorScheme;
    final compact=MediaQuery.sizeOf(context).width<380||MediaQuery.textScalerOf(context).scale(16)>22;
    return AppBar(automaticallyImplyLeading:false,toolbarHeight:90,
      backgroundColor:c.surface,foregroundColor:c.onSurface,surfaceTintColor:Colors.transparent,
      titleSpacing:12,leadingWidth:64,
      leading:Center(child:IconButton.filledTonal(tooltip:'Volver',onPressed:busy?null:()=>Navigator.maybePop(context),
        icon:const Icon(Icons.arrow_back_rounded),style:IconButton.styleFrom(backgroundColor:c.primaryContainer,foregroundColor:c.onPrimaryContainer))),
      title:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
        if(!compact)...[Text(overline.toUpperCase(),style:TextStyle(color:c.onSurfaceVariant,fontSize:10,fontWeight:FontWeight.w700,letterSpacing:1)),const SizedBox(height:4)],
        Text(title,maxLines:2,overflow:TextOverflow.ellipsis,style:TextStyle(color:c.onSurface,fontSize:compact?17:20,fontWeight:FontWeight.w800,height:1.2)),
      ]),
      actions:[Padding(padding:const EdgeInsets.only(right:10),child:ThemeButton(foregroundColor:c.primary))],
      bottom:PreferredSize(preferredSize:const Size.fromHeight(1),child:Container(height:1,color:c.outlineVariant)),
    );
  }
}
