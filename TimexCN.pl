#! /usr/bin/perl -w
# recognize Chinese numbers and time expressions
# puts <NUM></NUM> or <TIME></TIME> around them.(max. matching)
# works in both Simplified CN and Traditional CN (UTF8)coding, but tuned better in Simplified CN
# W.Liu @ Univ. of Sheffield, 3 April 2006
use utf8;
binmode STDOUT, "utf8";
%dictionary = ();
%numbers1 =
 ("0"=>0,
  "1"=>1,
  "2"=>2,
  "3"=>3,
  "4"=>4,
  "5"=>5,
  "6"=>6,
  "7"=>7,
  "8"=>8,
  "9"=>9,
  "\x{25CB}"=>0,
  "\x{4E00}"=>1,
  "\x{4E8C}"=>2,
  "\x{4E24}"=>2,	#两
  "\x{5169}"=>2,	#兩
  "\x{4E09}"=>3,
  "\x{56DB}"=>4,
  "\x{4E94}"=>5,
  "\x{516D}"=>6,
  "\x{4E03}"=>7,
  "\x{516B}"=>8,
  "\x{4E5D}"=>9); #〇一二三四五六七八九
						
%numbers2 =
	 ("\x{96F6}"=>0,
		"\x{58F9}"=>1,
		"\x{8D30}"=>2,
		"\x{53C1}"=>3,
		"\x{8086}"=>4,
		"\x{4F0D}"=>5,
		"\x{9646}"=>6,
		"\x{67D2}"=>7,
		"\x{634C}"=>8,
		"\x{7396}"=>9); #零壹贰叁肆伍陆柒捌玖
						
%scale1 =  
	 ("\x{5341}"=>10,
		"\x{767E}"=>100,
		"\x{5343}"=>1000,
		"\x{4E07}"=>10000,
		"\x{4EBF}"=>100000000 ); # 十百千万亿

%scale2 =  
	 ("\%"=>'%',
	  "\x{62FE}"=>10,
		"\x{4F70}"=>100,
		"\x{4EDF}"=>1000,
		"\x{842C}"=>10000,
		"\x{5104}"=>100000000);			#拾佰仟萬億
		
%dots = 
	("."=>'.',
	 "\x{30FB}"=>'middle.',					# middile . seems the code is 30FB
	 "\x{70B9}"=>'点',
	 "\x{9EDE}"=>'點');							#.点點
	 
#%punc = 
#(	 
#)

#stop word dictionary
#these words contains number character, but they are part of a legal CN word.
%dictionary = 
	("\x{96F6}\x{552E}"=>1,				#零售
	 "\x{96F6}\x{4EF6}"=>1,				#零件
	 "\x{96F6}\x{7528}"=>1,				#零用
	 "\x{96F6}\x{82B1}"=>1,				#零花
	 "\x{4E94}\x{91D1}"=>1,				#五金
	 "\x{516B}\x{8FBE}"=>1,				#八达
	 "\x{5341}\x{5206}"=>1,				#十分
	 "\x{4E24}\x{4F1A}"=>1,				#两会
	 "\x{4E24}\x{5CB8}"=>1,				#两岸
	 "\x{56DB}\x{5DDD}"=>1,				#四川
	 "\x{961F}\x{4F0D}"=>1,     	#队伍
	 "\x{968A}\x{4F0D}"=>1,				#隊伍
	 "\x{653E}\x{8086}"=>1,				#放肆
	 "\x{8086}\x{65E0}"=>1,				#肆无
	 "\x{8086}\x{7121}"=>1,				#肆無
	 "\x{8086}\x{610F}"=>1,				#肆意
	 "\x{4E3A}\x{4F0D}"=>1,				#为伍
	 "\x{9646}\x{7EED}"=>1,				#陆续
	 "\x{5927}\x{9646}"=>1,				#大陆
	 "\x{9646}\x{5730}"=>1,				#陆地
	 "\x{9646}\x{7A7A}"=>1,				#陆空
	 "\x{9646}\x{519B}"=>1,				#陆军
	 "\x{767B}\x{9646}"=>1,				#登陆
	 "\x{7740}\x{9646}"=>1,				#着陆
	 "\x{5106}\x{767E}"=>1,				#儆百
	 "\x{767E}\x{59D3}"=>1,				#百姓
	 "\x{4E07}\x{7D2B}"=>1,				#万紫
	 "\x{842C}\x{7D2B}"=>1,				#萬紫
	 "\x{5343}\x{7EA2}"=>1,				#千红
	 "\x{5343}\x{7D05}"=>1,				#千紅
	 "\x{5343}\x{79A7}"=>1,				#千禧
	 "\x{4E07}\x{5C81}"=>1,				#万岁
	 "\x{842C}\x{6B72}"=>1);			#萬歲
	 
#load dic
#open(DIC, "ambiword.txt")||die "cannot open anbiword.txt:$!\n";
#while(<DIC>){
#	chomp;

#}
#close DIC ; 
open(F,"<:utf8","$ARGV[0]");
while(<F>){

	my $offset = 0;          
	my $trigger = 0;
	my @cn_chars = split(//);
	my @indexes = ();
	my @num = ();
	my $cn_num = "";
  my $count1 = 0;  
  my $count2 = 0;

   if(/^\s*\d+\s*$/){ 
     s/(\d+)/<NUM>$1<\/NUM>/g;
#         print "$_";
         next;
     } 
  	
	 for(my $i=0;$i<@cn_chars; $i++){
		 $char = $cn_chars[$i] ;
		 #if contains the word in dictionary, leave it, although it has a "number" character in it.
#		if(@cn_chars == 2 && exists($dictionary{$lchars})
    if( @cn_chars >=2 ){
		my $start2 = "$cn_chars[0]"."$cn_chars[1]";
		if(exists($dictionary{$start2}) ){ next; }
		if( $i >0 && $i<$#cn_chars){
		 my $lchars = "$cn_chars[$i-1]"."$cn_chars[$i]";
		 my $rchars = "$cn_chars[$i]"."$cn_chars[$i+1]";
#		 print "char is: [$char] left ->[$lchars] \t right->[$rchars]\n";

		if(exists($dictionary{$lchars}) || exists($dictionary{$rchars}) ){
#		    print "skip character [$char], go to next\n";					
		    next ;
		    }
		  }
		}
		# cases like "一般， 一会，一起。。。"
		# this will eliminate valid time expressions like 三十 <一日>， will replace back at the end
		if( ($char eq "\x{4E00}") && ($cn_chars[$i-1] ne "\x{4E4B}")&&   #"之一"还是算进去的
		!exists($numbers1{$cn_chars[$i+1]}) && 
		!exists($scale1{$cn_chars[$i+1]}) && 
		!exists($numbers2{$cn_chars[$i+1]}) && 
		!exists($scale2{$cn_chars[$i+1]}) &&
		!exists($dots{$cn_chars[$i+1]})){
#			print "$dots{$cn_chars[$i+1]} does not follow CN 1, so jumped\n";
			next;
		}

		# if the first CN digit is met. 
		if(exists($numbers1{$char}) || exists($scale1{$char})|| exists($numbers2{$char}) || exists($scale2{$char})){
			$trigger = 1;
			$cn_num .= $char ;			
			 next ;
		}
#		if($trigger ==1 && (($char eq "\x{70B9}")||($char eq "\x{9EDE}")||($char eq '.') ) ){	#点 點
		if($trigger ==1 && (exists($dots{$char})) ){
		  $cn_num .= $char ;
		   next;
	  }		  

	 $trigger= 0;		
	 
    if($cn_num ne ""){
	  push (@num,$cn_num);     
	  $cn_num = "";
		}

  }#foreach
  		$offset = 0;
		for (my $j=0;$j<@num;$j++){
#			print " line->$j substitue $num[$j] :";
 			$pattern = $num[$j];
				s/$pattern/<N>/;
			}
			$count = 0;

			while(/<N>/g){
				$pattern = $num[$count++] ; 
				s/<N>/<NUM>$pattern<\/NUM>/;
			}
			
			s/<NUM>((?:(?!<NUM>).)*)<\/NUM>(O+)<NUM>((?:(?!<NUM>).)*)<\/NUM>/<NUM>$1$2$3<\/NUM>/g;  # I can't believe in some of the CNA news, 
			s/<NUM>((?:(?!<NUM>).)*)<\/NUM>(O+)/<NUM>$1$2<\/NUM>/g;																	# they use uppercase O to mean zero(0) !!!
			s/(\x{7B2C}\x{4E00})/<NUM>$1<\/NUM>/g;																									#第一， 一is very annoying!!
			s/(\x{7B2C})<NUM>((?:(?!<NUM>).)*)<\/NUM>/<NUM>$1$2<\/NUM>/g;														#第xx  加上序数词
			
			if($_ =~ m/<NUM>((?:(?!<NUM>).)*)<\/NUM>(\x{6210})/){				#<>x<>成    
					if(exists($numbers1{$1})){
						s/<NUM>((?:(?!<NUM>).)*)<\/NUM>(\x{6210})/<NUM>$1$2<\/NUM>/; 
					}
			}
			
#			print "NUM TAG: $_";

			# the following tags the time expressions, the principle is a number expression followed by time character is a time expression.
			s/<NUM>((?:(?!<NUM>).)*)<\/NUM>(\x{5E74})<NUM>((?:(?!<NUM>).)*)<\/NUM>(\x{6708})<NUM>((?:(?!<NUM>).)*)<\/NUM>(\x{65E5})/<TIME>$1$2$3$4$5$6<\/TIME>/g;  	# xx年yy月zz日
			s/<NUM>((?:(?!<NUM>).)*)<\/NUM>(\x{5E74})<NUM>((?:(?!<NUM>).)*)<\/NUM>(\x{6708})<NUM>((?:(?!<NUM>).)*)<\/NUM>(\x{53F7})/<TIME>$1$2$3$4$5$6<\/TIME>/g;  	# xx年yy月zz号
			s/<NUM>((?:(?!<NUM>).)*)<\/NUM>(\x{5C0F}\x{65F6}|\x{65F6})<NUM>((?:(?!<NUM>).)*)<\/NUM>(\x{5206})<NUM>((?:(?!<NUM>).)*)<\/NUM>(\x{79D2})/<TIME>$1$2$3$4$5$6<\/TIME>/g;		#xx(小)时(65F6)yy分(5206)zz秒(79D2)
			s/<NUM>((?:(?!<NUM>).)*)<\/NUM>(\x{5C0F}\x{6642}|\x{6642})<NUM>((?:(?!<NUM>).)*)<\/NUM>(\x{5206})<NUM>((?:(?!<NUM>).)*)<\/NUM>(\x{79D2})/<TIME>$1$2$3$4$5$6<\/TIME>/g;		#xx(小)時(65F6)yy分(5206)zz秒(79D2)
			
			s/<NUM>((?:(?!<NUM>).)*)<\/NUM>(\x{5E74})<NUM>((?:(?!<NUM>).)*)<\/NUM>(\x{6708})/<TIME>$1$2$3$4<\/TIME>/g;	#x年y月
			s/<NUM>((?:(?!<NUM>).)*)<\/NUM>(\x{6708})<NUM>((?:(?!<NUM>).)*)<\/NUM>(\x{65E5})/<TIME>$1$2$3$4<\/TIME>/g; 	#x月x日
			s/<NUM>((?:(?!<NUM>).)*)<\/NUM>(\x{6708})<NUM>((?:(?!<NUM>).)*)<\/NUM>(\x{53F7})/<TIME>$1$2$3$4<\/TIME>/g; 	#x月x号
			s/<NUM>((?:(?!<NUM>).)*)<\/NUM>(\x{5C0F}\x{65F6}|\x{65F6})<NUM>((?:(?!<NUM>).)*)<\/NUM>(\x{5206})/<TIME>$1$2$3$4<\/TIME>/g;  #xx(小)时(65F6)yy分(5206)
			s/<NUM>((?:(?!<NUM>).)*)<\/NUM>(\x{5C0F}\x{6642}|\x{6642})<NUM>((?:(?!<NUM>).)*)<\/NUM>(\x{5206})/<TIME>$1$2$3$4<\/TIME>/g;  #xx(小)時(6642)yy分(5206)
			s/<NUM>((?:(?!<NUM>).)*)<\/NUM>(\x{5206})<NUM>((?:(?!<NUM>).)*)<\/NUM>(\x{79D2})/<TIME>$1$2$3$4<\/TIME>/g;  #xx分(65F6)yy秒(79D2)
			s/<NUM>((?:(?!<NUM>).)*)<\/NUM>(\x{4E2A}{0,1}\x{661F}\x{671F})/<TIME>$1$2<\/TIME>/g;		#<>x<>(个)星期
			s/(\x{661F}\x{671F})<NUM>((?:(?!<NUM>).)*)<\/NUM>/<TIME>$1$2<\/TIME>/g;								 	#星期x
			s/(\x{793C}\x{62DC})<NUM>((?:(?!<NUM>).)*)<\/NUM>/<TIME>$1$2<\/TIME>/g;									#礼拜x
			s/<NUM>((?:(?!<NUM>).)*)<\/NUM>(\x{5206}\x{949F})/<TIME>$1$2<\/TIME>/g;									#x分钟
			s/<NUM>((?:(?!<NUM>).)*)<\/NUM>(\x{5206}\x{937E})/<TIME>$1$2<\/TIME>/g;									#x分鍾
			s/<NUM>((?:(?!<NUM>).)*)<\/NUM>(\x{5C0F}(\x{65F6}|\x{6642}))/<TIME>$1$2<\/TIME>/g;			#x小时(時) 
      
			s/<NUM>(\x{767E})<\/NUM>(\x{5206}\x{70B9})/$1$2/g;																			#<NUM>百</NUM>分点
			s/<NUM>(\x{767E})<\/NUM>(\x{5206}\x{9EDE})/$1$2/g;																			#<NUM>百</NUM>分點
						   
			s/<NUM>((?:(?!<NUM>).)*)<\/NUM>(\x{5206}\x{4E4B})<NUM>((?:(?!<NUM>).)*)<\/NUM>/<NUM>$1$2$3<\/NUM>/g;	#x分之x
			
			
			s/<NUM>((?:(?!<NUM>).)*)<\/NUM>(\x{6708}{0,1}\x{4E00}\x{65E5})/<TIME>$1$2<\/TIME>/g;		#<NUM>xx<>(月)一日
			s/<NUM>((?:(?!<NUM>).)*)<\/NUM>(\x{4E00}(\x{65F6}|\x{6642}))/<TIME>$1$2<\/TIME>/g;			#<>xx<>一(时)時
			s/<NUM>((?:(?!<NUM>).)*)<\/NUM>(\x{4E00}\x{6708})/<TIME>$1$2<\/TIME>/g;									#<>xx<>一月
			s/<NUM>((?:(?!<NUM>).)*)<\/NUM>(\x{4E00}\x{5E74})/<TIME>$1$2<\/TIME>/g;									#<>xx<>一年
			s/<NUM>((?:(?!<NUM>).)*)<\/NUM>(\x{4E00}\x{6B72})/<TIME>$1$2<\/TIME>/g;									#<>xx<>一歲
			s/<NUM>((?:(?!<NUM>).)*)<\/NUM>(\x{4E00}\x{5C81})/<TIME>$1$2<\/TIME>/g;									#<>xx<>一岁
			s/<NUM>((?:(?!<NUM>).)*)<\/NUM>(\x{5468}{0,1}\x{5E74})/<TIME>$1$2<\/TIME>/g;						#<>x<>(周)年
			s/<NUM>((?:(?!<NUM>).)*)<\/NUM>(\x{6642})/<TIME>$1$2<\/TIME>/g;													#<>xx<>時
			
			s/<NUM>((?:(?!<NUM>).)*)<\/NUM>(\x{4E2A}\x{6708})/<TIME>$1$2<\/TIME>/g;									#<>个月
			s/<NUM>((?:(?!<NUM>).)*)<\/NUM>(\x{6708}\x{4EFD}|\x{6708})/<TIME>$1$2<\/TIME>/g;				#x月(份)
			s/<NUM>((?:(?!<NUM>).)*)<\/NUM>(\x{65E5}|\x{53F7}|\x{5929})/<TIME>$1$2<\/TIME>/g;				#x日 or 号 or 天
			s/<NUM>((?:(?!<NUM>).)*)<\/NUM>(\x{53F7})/<TIME>$1$2<\/TIME>/g;													#x
			

			$_ =~ s/<NUM>((?:(?!<NUM>).)*)<\/NUM>(\x{79D2})/<TIME>$1$2<\/TIME>/g;										#x秒
			
			s/<NUM>(\w{1,3})<\/NUM>(\x{4E00}\x{5E74})/<TIME>$1$2<\/TIME>/g;													#xxx一年
			s/<NUM>(\x{516B})<\/NUM>(\x{4E00}\w{0,2}\x{961F})/$1$2/g;																#八一xx队
						
			s/(\x{7B2C})<TIME>((?:(?!<TIME>).)*)<\/TIME>/<TIME>$1$2<\/TIME>/g;
			
			s/<TIME>((?:(?!<TIME>).)*)<\/TIME>(\x{4E00}\x{6708}\x{4E00}\x{65E5})/<TIME>$1$2<\/TIME>/g;#<NUM>xx<>一月一日
			s/<TIME>((?:(?!<TIME>).)*)<\/TIME>(\x{4E00})\x{79D2}/<TIME>$1$2<\/TIME>/g;								#<TIME>xxx</TIME>一秒
			s/<NUM>((?:(?!<NUM>).)*)<\/NUM>(\x{4E00}(\x{65F6}|\x{6642}))<NUM>((?:(?!<NUM>).)*)<\/NUM>/TIME>$1$2$3<\/TIME>/g;#<NUM>xx</NUM>一时(時)<NUM>xx</NUM>
			
			
			#simply replacing tags, 
#			s/<NUM>((?:(?!<NUM>).)*)<\/NUM>/NUM/g;
#			s/<TIME>((?:(?!<TIME>).)*)<\/TIME>/TIME/g;
			print "$_";

			
}#while

close F;
