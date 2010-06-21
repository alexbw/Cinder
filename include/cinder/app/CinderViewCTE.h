/*
 
 Created by Alex Wiltschko on 6/9/10.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that
 the following cocare met:
 
 * Redistributions of source code must retain the above copyright notice, this list of conditions and
 the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and
 the following disclaimer in the documentation and/or other materials provided with the distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
 WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
 ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 */

//
//  CinderViewCTE.h
//  cinder
//
// CinderViewCTE (Cocoa Touch Embedded)
// A CinderView meant to be instantiated in a NIB or by hand that exists
// within a normal CocoaTouch app.
// It can be attached to an MultiTouchApp, which would simply hum along
// independently from the rest of the CocoaTouch app, happily filling the 
// CinderViewCTE with wonderful Cinder content.


#pragma once

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

#include "cinder/gl/gl.h"
#include "cinder/app/AppCocoaTouch.h"
#include "cinder/app/Renderer.h"

#include <map>



@interface CinderViewCTE : UIView
{
@private
	BOOL animating;
	NSInteger animationFrameInterval;
	
	NSTimer					*animationTimer;

	std::map<UITouch*,uint32_t>	mTouchIdMap;
	
@public
	ci::app::AppCocoaTouch		*mApp;
	ci::app::Renderer			*mRenderer;
	
}

@property ci::app::AppCocoaTouch *mApp;
@property ci::app::Renderer	*mRenderer;
@property (readonly, nonatomic, getter=isAnimating) BOOL animating;
@property (nonatomic) NSInteger animationFrameInterval;
@property (nonatomic, retain) NSTimer *animationTimer;
- (id)initWithCoder:(NSCoder *)aDecoder;
- (id)initWithFrame:(CGRect)frame;
- (void)launchApp;
- (BOOL)ableToDraw;
- (void)startAnimation;
- (void)layoutSubviews;
- (void)drawView:(id)sender;
- (void)stopAnimation;


- (void)setApp:(ci::app::AppCocoaTouch *)app;
- (ci::app::AppCocoaTouch *)getApp;
- (void)setRenderer:(ci::app::Renderer *)renderer;
- (ci::app::Renderer *)getRenderer;

- (uint32_t)addTouchToMap:(UITouch*)touch;
- (void)removeTouchFromMap:(UITouch*)touch;
- (uint32_t)findTouchInMap:(UITouch*)touch;
- (void)updateActiveTouches;
- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event;


@end