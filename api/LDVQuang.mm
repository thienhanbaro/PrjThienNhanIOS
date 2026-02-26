#import "HeaderAPI.h"
#import <UIKit/UIKit.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#include "imgui/imgui.h"
#include "imgui/imgui_internal.h"

static NSString *const kLogoURL = @"https://sf-static.upanhlaylink.com/img/image_20260226907c3e336f9e71dc9b4eec2fe9b16236.jpg"; // Thay link logo thật của bạn
static float rotationAngle = 0.0f;

@interface LDVQuang : NSObject
@property (nonatomic, strong) NSString *cl; 
@property (nonatomic, assign) BOOL im;      
@property (nonatomic, assign) BOOL sm;      
@property (nonatomic, assign) int st;       
@property (nonatomic, strong) NSString *ms; 
@property (nonatomic, strong) id<MTLTexture> logoTex;
+ (instancetype)sharedInstance;
@end

@implementation LDVQuang

+ (instancetype)sharedInstance {
    static LDVQuang *s;
    static dispatch_once_t o;
    dispatch_once(&o, ^{ s = [[LDVQuang alloc] init]; s.sm = NO; });
    return s;
}

- (NSString *)ga {
    cpu_subtype_t s;
    size_t z = sizeof(s);
    sysctlbyname("hw.cpusubtype", &s, &z, NULL, 0);
    return (s == 2) ? @"arm64e (A12+)" : @"arm64";
}

- (NSString *)ep:(NSString *)p {
    NSData *d = [p dataUsingEncoding:NSUTF8StringEncoding];
    const char *b = (const char *)[d bytes];
    NSMutableString *r = [NSMutableString string];
    for (NSUInteger i = 0; i < [d length]; i++) {
        [r appendFormat:@"%02x", b[i] ^ 0x7A];
    }
    return r;
}

+ (void)load {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[LDVQuang sharedInstance] sp];
    });
}

- (void)sp {
    self.sm = YES; 
    self.st = 0; 
    self.ms = @"Đang tải dữ liệu từ máy chủ..."; 
    NSString *raw = [NSString stringWithFormat:@"action=init&token=%@", [HeaderAPI pToken]];
    [self pw:[NSString stringWithFormat:@"%@?v=%@", [HeaderAPI bURL], [self ep:raw]]];
}

- (void)pw:(NSString *)u {
    [[[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:u] completionHandler:^(NSData *d, NSURLResponse *r, NSError *e) {
        if (e || !d) { self.ms = @"Lỗi kết nối!"; return; }
        NSDictionary *j = [NSJSONSerialization JSONObjectWithData:d options:0 error:nil];
        if (j && [j[@"status"] boolValue]) {
            self.cl = j[@"contact"];
            self.im = [j[@"maintenance"] boolValue];
            dispatch_async(dispatch_get_main_queue(), ^{ [self hi]; });
        }
    }] resume];
}

- (void)hi {
    if (self.im) { self.ms = @"Hệ thống đang bảo trì!"; return; }
    NSString *sk = [[NSUserDefaults standardUserDefaults] objectForKey:@"saved_license_key"];
    if (sk) { 
        self.st = 0; 
        self.ms = @"Đang kiểm tra Key..."; 
        [self ec:[HeaderAPI bURL] k:sk]; 
    } else { self.st = 3; }
}

- (void)ec:(NSString *)b k:(NSString *)k {
    NSString *idv = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    NSString *raw = [NSString stringWithFormat:@"action=check&token=%@&key=%@&uuid=%@", [HeaderAPI pToken], k, idv];
    NSString *u = [NSString stringWithFormat:@"%@?v=%@", b, [self ep:raw]];
    [[[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:u] completionHandler:^(NSData *d, NSURLResponse *r, NSError *e) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (e || !d) { self.st = 2; self.ms = @"Lỗi máy chủ!"; return; }
            NSDictionary *j = [NSJSONSerialization JSONObjectWithData:d options:0 error:nil];
            if ([j[@"status"] boolValue]) {
                [[NSUserDefaults standardUserDefaults] setObject:k forKey:@"saved_license_key"];
                self.st = 1;
            } else {
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"saved_license_key"];
                self.st = 2; self.ms = @"Key không hợp lệ!";
            }
        });
    }] resume];
}

void DrawRotatingLogo(id<MTLTexture> tex, ImVec2 center, float size, float angle) {
    ImDrawList* dl = ImGui::GetWindowDrawList();
    float cos_a = cosf(angle); float sin_a = sinf(angle);
    ImVec2 pos[4]; float h = size * 0.5f;
    ImVec2 v[4] = { ImVec2(-h,-h), ImVec2(h,-h), ImVec2(h,h), ImVec2(-h,h) };
    for (int n = 0; n < 4; n++) {
        pos[n].x = center.x + (v[n].x * cos_a - v[n].y * sin_a);
        pos[n].y = center.y + (v[n].x * sin_a + v[n].y * cos_a);
    }
    if (tex) dl->AddImageQuad((ImTextureID)tex, pos[0], pos[1], pos[2], pos[3]);
    else dl->AddCircleFilled(center, 30.0f, IM_COL32(255, 255, 255, 150));
}

- (void)drawMenu {
    if (!self.sm) return;
    ImGui::SetNextWindowSize(ImVec2(320, 260));
    ImGui::Begin("XÁC THỰC THIÊN NHÂN", NULL, ImGuiWindowFlags_NoCollapse | ImGuiWindowFlags_NoResize);
    ImVec2 p = ImGui::GetWindowPos(); ImVec2 s = ImGui::GetWindowSize();
    ImVec2 c = ImVec2(p.x + s.x/2, p.y + 75);

    if (self.st == 0) {
        rotationAngle += 0.05f;
        DrawRotatingLogo(self.logoTex, c, 60.0f, rotationAngle);
        ImGui::SetCursorPosY(130); [self tc:[self.ms UTF8String]];
    } else if (self.st == 1) {
        ImGui::SetCursorPosY(120); [self tc:"XÁC THỰC THÀNH CÔNG!"];
        ImGui::Text("Chip: %s", [[self ga] UTF8String]);
        if (ImGui::Button("VÀO GAME", ImVec2(-1, 40))) self.sm = NO;
    } else {
        ImGui::SetCursorPosY(70); [self tc:(self.st == 2 ? [self.ms UTF8String] : "VUI LÒNG NHẬP KEY")];
        static char k[64] = ""; ImGui::SetCursorPosY(140); ImGui::InputText("##k", k, 64);
        if (ImGui::Button("ĐĂNG NHẬP", ImVec2(-1, 35))) {
            self.st = 0; self.ms = @"Đang kiểm tra Key...";
            [self ec:[HeaderAPI bURL] k:[NSString stringWithUTF8String:k]];
        }
        if (ImGui::Button("LIÊN HỆ ADMIN", ImVec2(-1, 30))) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.cl] options:@{} completionHandler:nil];
        }
    }
    ImGui::End();
}

- (void)tc:(const char*)t {
    float w = ImGui::GetWindowSize().x; float tw = ImGui::CalcTextSize(t).x;
    ImGui::SetCursorPosX((w - tw) / 2); ImGui::Text("%s", t);
}
@end
