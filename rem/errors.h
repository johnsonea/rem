//
//  errors.h
//  rem
//
//  Created by Erik A Johnson on 10/29/19.
//  Copyright © 2019 kykim, inc. All rights reserved.
//

#ifndef errors_h
#define errors_h

#define MY_ERROR_DOMAIN @"edu.usc.johnsone.rem"

typedef enum _ExitStatus {
    EXIT_CLEAN = 99,
    EXIT_NORMAL = 0,
    EXIT_FAIL_ALLOC,
    EXIT_FAIL_NOINIT,
    EXIT_AUTH_UNKNOWNRESPONSE,
    EXIT_ACCESS_DENIED,
    EXIT_ACCESS_RESTRICTED,
    EXIT_ACCESS_NOTGRANTED,
    EXIT_ACCESS_TIMEDOUT,
    EXIT_CMD_UNKNOWN,
    EXIT_INVARG_NOSUCHCALENDAR,
    EXIT_INVARG_NOID,
    EXIT_INVARG_EMPTYCALENDAR,
    EXIT_INVARG_IDRANGE,
    EXIT_FAIL_ADD,
    EXIT_FAIL_RM,
    EXIT_FAIL_COMPLETE,
} ExitStatus;


#endif /* errors_h */
