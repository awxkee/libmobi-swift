//
//  toolchain.c
//  
//
//  Created by Radzivon Bartoshyk on 21/09/2022.
//

#include "toolchain.h"
#include "common.h"
#include <stdio.h>
#include <string.h>
# define MINIZ_HEADER_FILE_ONLY
# include "miniz.c"

#define EPUB_CONTAINER "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n\
<container version=\"1.0\" xmlns=\"urn:oasis:names:tc:opendocument:xmlns:container\">\n\
<rootfiles>\n\
<rootfile full-path=\"OEBPS/content.opf\" media-type=\"application/oebps-package+xml\"/>\n\
</rootfiles>\n\
</container>"
#define EPUB_MIMETYPE "application/epub+zip"

int dump_rawml_parts(const MOBIRawml *rawml, const char *fullpath) {
    if (rawml == NULL) {
        printf("Rawml structure not initialized\n");
        return MOBI_TOOLCHAIN_ERROR;
    }

    char newdir[FILENAME_MAX];
    if (create_dir(newdir, sizeof(newdir), fullpath, "_markup") == MOBI_TOOLCHAIN_ERROR) {
        return MOBI_TOOLCHAIN_ERROR;
    }
    printf("Saving markup to %s\n", newdir);

    /* create META_INF directory */
    char opfdir[FILENAME_MAX];
    if (create_subdir(opfdir, sizeof(opfdir), newdir, "META-INF") == MOBI_TOOLCHAIN_ERROR) {
        return MOBI_TOOLCHAIN_ERROR;
    }

    /* create container.xml */
    if (write_to_dir(opfdir, "container.xml", (const unsigned char *) EPUB_CONTAINER, sizeof(EPUB_CONTAINER) - 1) == MOBI_TOOLCHAIN_ERROR) {
        return MOBI_TOOLCHAIN_ERROR;
    }

    /* create mimetype file */
    if (write_to_dir(opfdir, "mimetype", (const unsigned char *) EPUB_MIMETYPE, sizeof(EPUB_MIMETYPE) - 1) == MOBI_TOOLCHAIN_ERROR) {
        return MOBI_TOOLCHAIN_ERROR;
    }

    /* create OEBPS directory */
    if (create_subdir(opfdir, sizeof(opfdir), newdir, "OEBPS") == MOBI_TOOLCHAIN_ERROR) {
        return MOBI_TOOLCHAIN_ERROR;
    }

    /* output everything else to OEBPS dir */
    strcpy(newdir, opfdir);
    char partname[FILENAME_MAX];
    if (rawml->markup != NULL) {
        /* Linked list of MOBIPart structures in rawml->markup holds main text files */
        MOBIPart *curr = rawml->markup;
        while (curr != NULL) {
            MOBIFileMeta file_meta = mobi_get_filemeta_by_type(curr->type);
            snprintf(partname, sizeof(partname), "part%05zu.%s", curr->uid, file_meta.extension);
            if (write_to_dir(newdir, partname, curr->data, curr->size) == MOBI_TOOLCHAIN_ERROR) {
                return MOBI_TOOLCHAIN_ERROR;
            }
            printf("%s\n", partname);
            curr = curr->next;
        }
    }
    if (rawml->flow != NULL) {
        /* Linked list of MOBIPart structures in rawml->flow holds supplementary text files */
        MOBIPart *curr = rawml->flow;
        /* skip raw html file */
        curr = curr->next;
        while (curr != NULL) {
            MOBIFileMeta file_meta = mobi_get_filemeta_by_type(curr->type);
            snprintf(partname, sizeof(partname), "flow%05zu.%s", curr->uid, file_meta.extension);
            if (write_to_dir(newdir, partname, curr->data, curr->size) == ERROR) {
                return MOBI_TOOLCHAIN_ERROR;
            }
            printf("%s\n", partname);
            curr = curr->next;
        }
    }
    if (rawml->resources != NULL) {
        /* Linked list of MOBIPart structures in rawml->resources holds binary files, also opf files */
        MOBIPart *curr = rawml->resources;
        /* jpg, gif, png, bmp, font, audio, video also opf, ncx */
        while (curr != NULL) {
            MOBIFileMeta file_meta = mobi_get_filemeta_by_type(curr->type);
            if (curr->size > 0) {
                int n;
                if (file_meta.type == T_OPF) {
                    n = snprintf(partname, sizeof(partname), "%s%ccontent.opf", newdir, separator);
                } else {
                    n = snprintf(partname, sizeof(partname), "%s%cresource%05zu.%s", newdir, separator, curr->uid, file_meta.extension);
                }
                if (n < 0) {
                    printf("Creating file name failed\n");
                    return MOBI_TOOLCHAIN_ERROR;
                }
                if ((size_t) n >= sizeof(partname)) {
                    printf("File name too long: %s\n", partname);
                    return MOBI_TOOLCHAIN_ERROR;
                }

                if (write_file(curr->data, curr->size, partname) == ERROR) {
                    return MOBI_TOOLCHAIN_ERROR;
                }

            }
            curr = curr->next;
        }
    }
    return MOBI_TOOLCHAIN_SUCCESS;
}

int create_epub(const MOBIRawml *rawml, const char *fullpath) {
    if (rawml == NULL) {
        return MOBI_TOOLCHAIN_ERROR;
    }

    /* create zip (epub) archive */
    mz_zip_archive zip;
    memset(&zip, 0, sizeof(mz_zip_archive));
    mz_bool mz_ret = mz_zip_writer_init_file(&zip, fullpath, 0);
    if (!mz_ret) {
        return MOBI_TOOLCHAIN_ERROR;
    }
    /* start adding files to archive */
    mz_ret = mz_zip_writer_add_mem(&zip, "mimetype", EPUB_MIMETYPE, sizeof(EPUB_MIMETYPE) - 1, MZ_NO_COMPRESSION);
    if (!mz_ret) {
        mz_zip_writer_end(&zip);
        return MOBI_TOOLCHAIN_ERROR;
    }
    mz_ret = mz_zip_writer_add_mem(&zip, "META-INF/container.xml", EPUB_CONTAINER, sizeof(EPUB_CONTAINER) - 1, (mz_uint)MZ_DEFAULT_COMPRESSION);
    if (!mz_ret) {
        mz_zip_writer_end(&zip);
        return MOBI_TOOLCHAIN_ERROR;
    }
    char partname[FILENAME_MAX];
    if (rawml->markup != NULL) {
        /* Linked list of MOBIPart structures in rawml->markup holds main text files */
        MOBIPart *curr = rawml->markup;
        while (curr != NULL) {
            MOBIFileMeta file_meta = mobi_get_filemeta_by_type(curr->type);
            snprintf(partname, sizeof(partname), "OEBPS/part%05zu.%s", curr->uid, file_meta.extension);
            mz_ret = mz_zip_writer_add_mem(&zip, partname, curr->data, curr->size, (mz_uint) MZ_DEFAULT_COMPRESSION);
            if (!mz_ret) {
                mz_zip_writer_end(&zip);
                return MOBI_TOOLCHAIN_ERROR;
            }
            curr = curr->next;
        }
    }
    if (rawml->flow != NULL) {
        /* Linked list of MOBIPart structures in rawml->flow holds supplementary text files */
        MOBIPart *curr = rawml->flow;
        /* skip raw html file */
        curr = curr->next;
        while (curr != NULL) {
            MOBIFileMeta file_meta = mobi_get_filemeta_by_type(curr->type);
            snprintf(partname, sizeof(partname), "OEBPS/flow%05zu.%s", curr->uid, file_meta.extension);
            mz_ret = mz_zip_writer_add_mem(&zip, partname, curr->data, curr->size, (mz_uint) MZ_DEFAULT_COMPRESSION);
            if (!mz_ret) {
                mz_zip_writer_end(&zip);
                return MOBI_TOOLCHAIN_ERROR;
            }
            curr = curr->next;
        }
    }
    if (rawml->resources != NULL) {
        /* Linked list of MOBIPart structures in rawml->resources holds binary files, also opf files */
        MOBIPart *curr = rawml->resources;
        /* jpg, gif, png, bmp, font, audio, video, also opf, ncx */
        while (curr != NULL) {
            MOBIFileMeta file_meta = mobi_get_filemeta_by_type(curr->type);
            if (curr->size > 0) {
                if (file_meta.type == T_OPF) {
                    snprintf(partname, sizeof(partname), "OEBPS/content.opf");
                } else {
                    snprintf(partname, sizeof(partname), "OEBPS/resource%05zu.%s", curr->uid, file_meta.extension);
                }
                mz_ret = mz_zip_writer_add_mem(&zip, partname, curr->data, curr->size, (mz_uint) MZ_DEFAULT_COMPRESSION);
                if (!mz_ret) {
                    mz_zip_writer_end(&zip);
                    return MOBI_TOOLCHAIN_ERROR;
                }
            }
            curr = curr->next;
        }
    }
    /* Finalize epub archive */
    mz_ret = mz_zip_writer_finalize_archive(&zip);
    if (!mz_ret) {
        mz_zip_writer_end(&zip);
        return MOBI_TOOLCHAIN_ERROR;
    }
    mz_ret = mz_zip_writer_end(&zip);
    if (!mz_ret) {
        return MOBI_TOOLCHAIN_ERROR;
    }
    return MOBI_TOOLCHAIN_SUCCESS;
}
