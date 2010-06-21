/*
 Copyright (c) 2010, The Barbarian Group
 All rights reserved.

 Redistribution and use in source and binary forms, with or without modification, are permitted provided that
 the following conditions are met:

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

#include "cinder/audio/FftProcessorImplGeneric.h"
#include "fft4g.h"

namespace cinder { namespace audio {

FftProcessorImplGeneric::FftProcessorImplGeneric( uint16_t aBandCount )
	: FftProcessorImpl( aBandCount )
{
	ip = (int *)calloc((2 + sqrt(aBandCount)), sizeof(int));
	w  = (double *)calloc((aBandCount - 1), sizeof(double));
	ip[0] = 0; // Need to set this before the first time we run the FFT
	holdingBuffer	= (double *)calloc(aBandCount*2, sizeof(double));
//	outData			= (float *)calloc(aBandCount, sizeof(float));
	
	if( mBandCount & ( mBandCount - 1 ) ) {
		//TODO: not power of 2
	}
	
	
}

FftProcessorImplGeneric::~FftProcessorImplGeneric()
{
	free( ip );
	free( w );
	free( holdingBuffer );
//	free( outData );
	
}

shared_ptr<float> FftProcessorImplGeneric::process( const float * inData )
{
	
	memset(holdingBuffer, 0, sizeof(double)*mBandCount);
		   
	for (int i=0; i < mBandCount*2; ++i)
		holdingBuffer[i] = (double)inData[i];

	rdft(mBandCount*2, 1, holdingBuffer, ip, w);
	
	float * outData = new float[mBandCount];
	for (int i=0; i<mBandCount; ++i) {
		outData[i] = (float)sqrt(holdingBuffer[i*2]*holdingBuffer[i*2] + holdingBuffer[i*2+1]*holdingBuffer[i*2+1]);
	}
			
	return shared_ptr<float>( outData );;
}

}} //namespace