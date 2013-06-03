//  Copyright (C) 1999 AT&T Laboratories Cambridge. All Rights Reserved.
//
//  This file is part of the VNC system.
//
//  The VNC system is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 2 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307,
//  USA.
//
// TightVNC distribution homepage on the Web: http://www.tightvnc.com/
//
// If the source code for the VNC system is not available from the place whence 
// you received this file, check http://www.uk.research.att.com/vnc or contact
// the authors on vnc@uk.research.att.com for information on obtaining it.


/*
 * vncauth.c - Functions for VNC password management and authentication.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include "vncauth.h"
#include "d3des.h"


/*
 * We use a fixed key to store passwords, since we assume that our local
 * file system is secure but nonetheless don't want to store passwords
 * as plaintext.
 */

unsigned char fixedkey[8] = {23,82,107,6,35,78,88,7};


/*
 * Encrypt CHALLENGE_SIZE bytes in memory using a password.
 */

void vnc_encrypt_bytes(unsigned char *bytes, char *pwd)
{
    unsigned char key[8];
    unsigned int i;

    /* key is simply password padded with nulls */

    for (i = 0; i < 8; i++) {
        if (i < strlen(pwd)) {
            key[i] = pwd[i];
        } else {
            key[i] = 0;
        }
    }

    deskey(key, EN0);

    for (i = 0; i < CHALLENGE_SIZE; i += 8) {
		des(bytes+i, bytes+i);
    }
}


/*
 * Encrypt a password into the specified space.
 * output will be 8 bytes long - sufficient space 
 * should be allocated.
 */

void vnc_encrypt_pwd(unsigned char *output, char *pwd)
{
	unsigned int i;

    /* pad password with nulls */
    for (i = 0; i < MAX_PWD_LEN; i++) {
		if (i < strlen(pwd)) {
			output[i] = pwd[i];
		} else {	
			output[i] = 0;
		}
    }

    /* Do encryption in-place - this way we overwrite 
    // our copy of the plaintext password */
    deskey(fixedkey, EN0);
    des(output, output);
}


/*
 * Decrypt a password.  Returns a pointer to a newly allocated
 * string containing the password or a null pointer if the password could
 * not be retrieved for some reason.
 */

char * vnc_decrypt_pwd(const unsigned char *pwd)
{
    unsigned int i;
    unsigned char *ret = (unsigned char *)malloc(MAX_PWD_LEN + 1);

	memcpy(ret, pwd, MAX_PWD_LEN);

    for (i = 0; i < MAX_PWD_LEN; i++) {
		ret[i] = pwd[i];
    }

    deskey(fixedkey, DE1);
    des(ret, ret);

    ret[MAX_PWD_LEN] = 0;

    return (char *)ret;
}


