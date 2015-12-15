//
//  FEConstantsAndMacros.h
//  AKG
//
//  Created by Fabian Ehlert on 27.02.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#ifndef AKG_FEConstantsAndMacros_h
#define AKG_FEConstantsAndMacros_h

#define FELocalized(str) NSLocalizedString(str, nil)
#define FESWF(fmt, value, ...) [NSString stringWithFormat:fmt, value, ##__VA_ARGS__]

#endif
