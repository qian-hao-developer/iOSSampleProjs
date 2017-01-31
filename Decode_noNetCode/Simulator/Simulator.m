//
//  Simulator.m
//  Decode
//
//  Created by nekonosukiyaki on 14/11/27.
//  Copyright (c) 2014年 nekonosukiyaki. All rights reserved.
//

#import "Simulator.h"


@implementation Simulator

- (id)init {
    if (self == [super init]) {
        _text = nil;
        _text_bin = (Byte *)calloc(200, sizeof(Byte));
        _start_bin = (Byte)0x00;
        _end_bin = (Byte)0x00;
        _s_loop = 0;
        _t1_loop = 0;
        _t2_loop = 0;
        _e_loop = 0;
        _pre_trigger = 0;
        _pre_trigger1 = 0;
        _pre_trigger2 = 0;
        _isParaStart = NO;
        _bit = 0;
        _c_trigger = 0;
        _n_trigger = 1;
        _canPrintOut = NO;
        
        return self;
    }
    return nil;
}

- (void)judge:(double *)spectrum :(double)threshold {
    _start_bin = (Byte)0x00;
    
    //同期終了調査
    if (spectrum[458] > threshold && _isParaStart) {
        NSLog(@"同期終了調査入った！！！");
        if (_bit > 1) {
            NSLog(@"同期終了調査 bit>1");
            if (_e_loop == 0) {
                _pre_trigger = spectrum[458];
                _end_bin = [self exChangeBit:[self changeBit:spectrum :threshold]];
                _e_loop = 1;
            }
            else if (_e_loop == 1 && spectrum[458] > _pre_trigger) {
                _pre_trigger = spectrum[458];
                _end_bin = [self exChangeBit:[self changeBit:spectrum :threshold]];
            }
        }
    }
    //同期を終了する
    if ((_end_bin&(Byte)0x40) == (Byte)0x40) {
        NSLog(@"同期終了タグ入った！！");
        _isParaStart = NO;
        _t1_loop = 0;
        _t2_loop = 0;
        _e_loop = 0;
        _end_bin = (Byte)0x00;
        
//        NSLog(@"textbin:");
//        for (int i=0; i<_bit; i++) {
//            NSLog(@"%x",_text_bin[i]);
//        }
        _text = [self textBox:_text_bin :_bit];
        _bit = 0;
        _canPrintOut = YES;
    }
    
    
    //trigger1の場合
    if (spectrum[450] > threshold && _isParaStart && spectrum[458] < threshold) {
        NSLog(@"trig1検査入った！！");
        _c_trigger = 1;
        _t2_loop = 0;
        if (_t1_loop == 0) {
            if (_c_trigger == _n_trigger) {
                _pre_trigger1 = spectrum[450];
                _text_bin[_bit] = [self exChangeBit:[self changeBit:spectrum :threshold]];
                _bit++;
                _n_trigger = 2;
                _t1_loop = 1;
            }
        }
        else if (_t1_loop == 1 && spectrum[450] > _pre_trigger1) {
            _bit--;
            _text_bin[_bit] = [self exChangeBit:[self changeBit:spectrum :threshold]];
//            NSLog(@"trig1,loop: %x, bit: %d",_text_bin[_bit],_bit);
            _bit++;
            _pre_trigger1 = spectrum[450];
        }
    }
    
    
    //trigger2の場合
    if (spectrum[454] > threshold && _isParaStart && spectrum[458] < threshold) {
        NSLog(@"trig2検査入った！！");
        _c_trigger = 2;
        _t1_loop = 0;
        if (_t2_loop == 0) {
            if (_c_trigger == _n_trigger) {
                _pre_trigger2 = spectrum[454];
                _text_bin[_bit] = [self exChangeBit:[self changeBit:spectrum :threshold]];
                
//                NSLog(@"trig2,first: %x, bit: %d",_text_bin[_bit],_bit);
//                NSLog(@"exChangBit: %d",[self exChangeBit:[self changeBit:spectrum :threshold]]);
                _bit++;
                _n_trigger = 1;
                _t2_loop = 1;
            }
        }
        else if (_t2_loop == 1 && spectrum[454] > _pre_trigger2) {
            _bit--;
            _text_bin[_bit] = [self exChangeBit:[self changeBit:spectrum :threshold]];
//            NSLog(@"trig2,loop: %x, bit: %d",_text_bin[_bit],_bit);
            _bit++;
            _pre_trigger2 = spectrum[454];
        }
    }
    
    
    //同期開始フラグの条件文
    if (spectrum[458] > threshold && (!_isParaStart)) {
        NSLog(@"同期検査入った！！！");
        if (_s_loop == 0) {
            _pre_trigger = spectrum[458];
            _start_bin = [self exChangeBit:[self changeBit:spectrum :threshold]];
            _s_loop = 1;
        }
        else if (_s_loop == 1 && spectrum[458] > _pre_trigger) {
            _start_bin = [self exChangeBit:[self changeBit:spectrum :threshold]];
            _pre_trigger = spectrum[458];
        }
    }
    //同期フラグが真ならば同期を開始する
    if ((_start_bin&(Byte)0x80) == (Byte)0x80) {
        NSLog(@"同期開始入った！！！");
        _isParaStart = YES;
        _n_trigger = 2;
        _s_loop = 0;
        _t1_loop = 0;
        _t2_loop = 0;
        _e_loop = 0;
        _bit = 0;
        _text_bin = (Byte *)calloc(200, sizeof(Byte));
//        _text = nil;
    }
    
    if (_bit > 198) {
        _bit = 0;
    }
}

- (int *)changeBit:(double *)spectrum :(double)threshold {
    int binary[11] = {0,0,0,0,0,0,0,0,0,0,0};
    int *bp = &(binary[0]);
    int bitlist[11] = {
        417,422,426,430,434,438,442,446,450,454,458
    };
    
    for (int i=0; i<11; i++) {
        if (spectrum[bitlist[i]] > threshold) {
            binary[i] = 1;
        }
    }
    
    return bp;
}

- (Byte)exChangeBit:(int *)data {
    Byte binary = (Byte)0x00;
    Byte flag_bit[8] = {
        (Byte)0x80,(Byte)0x40,(Byte)0x20,(Byte)0x10,
        (Byte)0x08,(Byte)0x04,(Byte)0x02,(Byte)0x01
    };
    
    for (int i=0; i<8; i++) {
        if (data[i] == 1) {
            binary = (Byte)(binary | flag_bit[i]);
        }
    }
    
    return binary;
}

- (NSString *)textBox:(Byte *)text_bin :(int)bit {
//    for (int i=0; i<bit; i++) {
//        NSLog(@"inFunction_textbin: %x",text_bin[i]);
//    }
    NSString *text = nil;
    NSString *bacText = @"";
    NSLog(@"text:");
    for (int i=0; i<bit; i=i+2) {
        text = [[NSString alloc]initWithBytes:(text_bin+i) length:2 encoding:NSShiftJISStringEncoding];
        NSLog(@"%@",text);
        if (text == nil) {
            
        }
        else {
            bacText = [bacText stringByAppendingString:text];
        }
    }
//    text = [[NSString alloc]initWithBytes:text_bin length:(bit-2) encoding:NSShiftJISStringEncoding];
//    NSLog(@"bit: %d",bit);
//    NSLog(@"inFunction: %@",bacText);
    return bacText;
}

- (void)dealloc {
//    free(_text_bin);
    [super dealloc];
}

@end
