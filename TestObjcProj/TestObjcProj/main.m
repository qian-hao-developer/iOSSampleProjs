//
//  main.m
//  TestObjcProj
//
//  Created by nekonosukiyaki on 1/31/29 H.
//  Copyright © 29 Heisei nekonosukiyaki. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark - block test
// ------ block test ------ //
void pr(int (^block)(void)) {
    printf("%d\n", block());
}

void func(void) {
    int i;
    int (^blocks[10])(void);
    for (i = 0; i < 10; i++) {
        blocks[i] = ^{
            return i;
        };
    }
    for (i = 0; i < 10; i++) {
        pr(blocks[i]);
    }
}
// ------------------------ //

int main(int argc, const char * argv[]) {
//    @autoreleasepool {
        // insert code here...
        NSLog(@"Hello, World!");
        // testing code
        func();
//    }
    return 0;
}
