//
//  MMMHLSCoreFrameworkVersion.h
//  MMMHLSCoreFramework
//
//  Created by tangzhixin on 2017/11/13.
//  Copyright © 2017年 tangzhixin. All rights reserved.
//

#ifndef MMMHLSCoreFramework_h
#define MMMHLSCoreFramework_h

/*
 
 1.Major：具有相同名称但不同主版本号的程序集不可互换。例如，这适用于对产品的大量重写，这些重写使得无法实现向后兼容性。
 2.Minor
 ：如果两个程序集的名称和主版本号相同，而次版本号不同，这指示显著增强，但照顾到了向后兼容性。
 小数点后请取 0 -- 9 之间.
 例如，这适用于产品的修正版或完全向后兼容的新版本。
 3.Build
 ：内部版本号的不同表示对相同源所作的重新编译。这适合于更改处理器、平台或编译器的情况。
 4.Revision
 ：名称、主版本号和次版本号都相同但修订号不同的程序集应是完全可互换的。这适用于修复以前发布的程序集中的安全漏洞。
 5.程序集的只有内部版本号或修订号不同的后续版本被认为是先前版本的修补程序
 (Hotfix) 更新。
 
 */

/*更改版本号,只需要更改以下两个值，请遵循上面中文规范*/
static const int nMajor=1;
static const float fMinor=1.3f;

//OS_INLINE
__attribute__((destructor)) void IJKVersion(){
    char s_month[5];
    int day, year;
    sscanf(__DATE__, "%s %d %d", s_month, &day, &year);
    NSLog(@"------------------------------------------------");
    NSLog(@"MMMHLSCoreFramework IOS Library, Rev.%d\n", nMajor);
    NSLog(@"This build was on %s at %s.\n", __DATE__, __TIME__);
    NSLog(@"Version: v%d.%0.1f.\n", nMajor, fMinor);
    NSLog(@"Copyright %d Musical.ly, Inc.", year);
    NSLog(@"------------------------------------------------\n");
}

//release 1.1.1 :
//1、fix bug of finishWritingWithCompletionHandler cannot call method when status is 1。
//release 1.1.2 :
//1、ffmpeg size crop。
//release 1.1.3 :
// change hls_playlist_type 'event' to 'vod' mode;
//release 1.2.0 :
//crop framework size to about 8.8MB
#endif /* MMMHLSCoreFrameworkVersion_h */
