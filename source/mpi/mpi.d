// Some basic MPI routines
//
//

module mpi.mpi;

import std.algorithm, std.array, std.string;

// Type declarations. Internal structure not needed, only the address
// Note: C++ name mangling puts the implementation-specific structure names
// in the function calls. This means things like omp_communicator_t need to be defined
alias void* MPI_Comm;
alias void* MPI_Datatype;
alias void* MPI_Errhandler;
alias void* MPI_File;
alias void* MPI_Group;
alias void* MPI_Info;
alias void* MPI_Op;
alias void* MPI_Request;
alias void* MPI_Win;

/* The compiler id which OMPI was built with */
enum OPAL_BUILD_PLATFORM_COMPILER_FAMILYID = 1;

/* The compiler version which OMPI was built with */
enum OPAL_BUILD_PLATFORM_COMPILER_VERSION = 328449;

/* Define to 1 if you have the ANSI C header files. */
enum OPAL_STDC_HEADERS = 1;

/* Whether your compiler has __attribute__ deprecated or not */
auto OPAL_HAVE_ATTRIBUTE_DEPRECATED = 1;

/* Whether your compiler has __attribute__ deprecated with the optional argument */
enum OPAL_HAVE_ATTRIBUTE_DEPRECATED_ARGUMENT = 1;

/* Define to 1 if you have the <sys/time.h> header file. */
enum OPAL_HAVE_SYS_TIME_H = 1;

/* Define to 1 if you have the <sys/synch.h> header file. */
/* #undef OPAL_HAVE_SYS_SYNCH_H */

/* Define to 1 if the system has the type `long long'. */
enum OPAL_HAVE_LONG_LONG = 1;

/* The size of a `bool', as computed by sizeof. */
/* #undef OPAL_SIZEOF_BOOL */

/* The size of a `int', as computed by sizeof. */
/* #undef OPAL_SIZEOF_INT */

/* Maximum length of datarep string (default is 128) */
enum OPAL_MAX_DATAREP_STRING = 128;

/* Maximum length of error strings (default is 256) */
enum OPAL_MAX_ERROR_STRING = 256;

/* Maximum length of info keys (default is 36) */
enum OPAL_MAX_INFO_KEY = 36;

/* Maximum length of info vals (default is 256) */
enum OPAL_MAX_INFO_VAL = 256;

/* Maximum length of object names (default is 64) */
enum OPAL_MAX_OBJECT_NAME = 64;

/* Maximum length of port names (default is 1024) */
enum OPAL_MAX_PORT_NAME = 1024;

/* Maximum length of processor names (default is 256) */
enum OPAL_MAX_PROCESSOR_NAME = 256;

/* Whether we have FORTRAN LOGICAL*1 or not */
enum OMPI_HAVE_FORTRAN_LOGICAL1 = 1;

/* Whether we have FORTRAN LOGICAL*2 or not */
enum OMPI_HAVE_FORTRAN_LOGICAL2 = 1;

/* Whether we have FORTRAN LOGICAL*4 or not */
enum OMPI_HAVE_FORTRAN_LOGICAL4 = 1;

/* Whether we have FORTRAN LOGICAL*8 or not */
enum OMPI_HAVE_FORTRAN_LOGICAL8 = 1;

/* Whether we have FORTRAN INTEGER*1 or not */
enum OMPI_HAVE_FORTRAN_INTEGER1 = 1;

/* Whether we have FORTRAN INTEGER*16 or not */
enum OMPI_HAVE_FORTRAN_INTEGER16 = 0;

/* Whether we have FORTRAN INTEGER*2 or not */
enum OMPI_HAVE_FORTRAN_INTEGER2 = 1;

/* Whether we have FORTRAN INTEGER*4 or not */
enum OMPI_HAVE_FORTRAN_INTEGER4 = 1;

/* Whether we have FORTRAN INTEGER*8 or not */
enum OMPI_HAVE_FORTRAN_INTEGER8 = 1;

/* Whether we have FORTRAN REAL*16 or not */
enum OMPI_HAVE_FORTRAN_REAL16 = 1;

/* Whether we have FORTRAN REAL*2 or not */
enum OMPI_HAVE_FORTRAN_REAL2 = 0;

/* Whether we have FORTRAN REAL*4 or not */
enum OMPI_HAVE_FORTRAN_REAL4 = 1;

/* Whether we have FORTRAN REAL*8 or not */
enum OMPI_HAVE_FORTRAN_REAL8 = 1;

/* Whether we have float _Complex  or not */
enum HAVE_FLOAT__COMPLEX = 1;

/* Whether we have double _Complex  or not */
enum HAVE_DOUBLE__COMPLEX = 1;

/* Whether we have long double _Complex  or not */
enum HAVE_LONG_DOUBLE__COMPLEX = 1;

/* Type of MPI_Offset -- has to be defined here and typedef'ed later because mpi.h does not get AC SUBST's */
alias OMPI_MPI_OFFSET_TYPE = long;

/* Size of the MPI_Offset corresponding type */
enum OMPI_MPI_OFFSET_SIZE = 8;

/* Type of MPI_Count */
alias OMPI_MPI_COUNT_TYPE = long;

/* type to use for ptrdiff_t, if it does not exist, set to ptrdiff_t if it does exist */
alias OPAL_PTRDIFF_TYPE = ptrdiff_t;

/* Whether we want MPI cxx support or not */
enum OMPI_BUILD_CXX_BINDINGS = 1;

/* do we want to try to work around C++ bindings SEEK_* issue? */
enum OMPI_WANT_MPI_CXX_SEEK = 1;

/* Whether a const_cast on a 2-d array will work with the C++ compiler */
enum OMPI_CXX_SUPPORTS_2D_CONST_CAST = 1;

/* Whether OMPI was built with parameter checking or not */
enum OMPI_PARAM_CHECK = 1;

/* Whether or not we have compiled with C++ exceptions support */
enum OMPI_HAVE_CXX_EXCEPTION_SUPPORT = 0;

/* Major, minor, and release version of Open MPI */
enum OMPI_MAJOR_VERSION = 1;
enum OMPI_MINOR_VERSION = 10;
enum OMPI_RELEASE_VERSION = 2;

/* A  type that allows us to have sentinel type values that are still
   valid */
alias ompi_fortran_bogus_type_t = int;

/* C type corresponding to FORTRAN INTEGER */
alias ompi_fortran_integer_t = int;

/* Whether C compiler supports -fvisibility */
enum OPAL_C_HAVE_VISIBILITY = 1;

/* Whether OMPI should provide MPI File interface */
enum OMPI_PROVIDE_MPI_FILE_INTERFACE = 1;


/*
 * Miscellaneous constants
 */
enum MPI_ANY_SOURCE         = -1;                      /* match any source rank */
enum MPI_PROC_NULL          = -2;                     /* rank of null process */
enum MPI_ROOT               = -4;                     /* special value for intercomms */
enum MPI_ANY_TAG            = -1;                     /* match any message tag */
enum MPI_MAX_PROCESSOR_NAME = OPAL_MAX_PROCESSOR_NAME; /* max proc. name length */
enum MPI_MAX_ERROR_STRING  = OPAL_MAX_ERROR_STRING;  /* max error message length */
enum MPI_MAX_OBJECT_NAME    = OPAL_MAX_OBJECT_NAME;   /* max object name length */
enum MPI_MAX_LIBRARY_VERSION_STRING = 256;             /* max length of library version string */
enum MPI_UNDEFINED         = -32766;                  /* undefined stuff */
enum MPI_DIST_GRAPH        = 3;                       /* dist graph topology */
enum MPI_CART              = 1;                       /* cartesian topology */
enum MPI_GRAPH             = 2;                       /* graph topology */
enum MPI_KEYVAL_INVALID     = -1;                      /* invalid key value */

/*
 * More constants
 */
enum MPI_UNWEIGHTED          = (cast(void *) 2);          /* unweighted graph */
enum MPI_WEIGHTS_EMPTY       = (cast(void *) 3);          /* empty weights */
enum MPI_BOTTOM              = (cast(void *) 0);          /* base reference address */
enum MPI_IN_PLACE            = (cast(void *) 1);          /* in place buffer */
enum MPI_BSEND_OVERHEAD      = 128;                   /* size of bsend header + ptr */
enum MPI_MAX_INFO_KEY        = OPAL_MAX_INFO_KEY;     /* max info key length */
enum MPI_MAX_INFO_VAL        = OPAL_MAX_INFO_VAL;     /* max info value length */
enum MPI_ARGV_NULL           = (cast(char **) 0);         /* NULL argument vector */
enum MPI_ARGVS_NULL          = (cast(char ***) 0);        /* NULL argument vectors */
enum MPI_ERRCODES_IGNORE     = (cast(int *) 0);           /* don't return error codes */
enum MPI_MAX_PORT_NAME       = OPAL_MAX_PORT_NAME;    /* max port name length */
enum MPI_ORDER_C             = 0;                     /* C row major order */
enum MPI_ORDER_FORTRAN       = 1;                     /* Fortran column major order */
enum MPI_DISTRIBUTE_BLOCK    = 0;                     /* block distribution */
enum MPI_DISTRIBUTE_CYCLIC   = 1;                     /* cyclic distribution */
enum MPI_DISTRIBUTE_NONE     = 2;                     /* not distributed */
enum MPI_DISTRIBUTE_DFLT_DARG = (-1);                  /* default distribution arg */

static if (OMPI_PROVIDE_MPI_FILE_INTERFACE) {
/*
 * Since these values are arbitrary to Open MPI, we might as well make
 * them the same as ROMIO for ease of mapping.  These values taken
 * from ROMIO's mpio.h file.
 */
enum MPI_MODE_CREATE           =   1;  /* ADIO_CREATE */
enum MPI_MODE_RDONLY           =   2;  /* ADIO_RDONLY */
enum MPI_MODE_WRONLY           =   4;  /* ADIO_WRONLY  */
enum MPI_MODE_RDWR             =   8;  /* ADIO_RDWR  */
enum MPI_MODE_DELETE_ON_CLOSE  =  16;  /* ADIO_DELETE_ON_CLOSE */
enum MPI_MODE_UNIQUE_OPEN      =  32;  /* ADIO_UNIQUE_OPEN */
enum MPI_MODE_EXCL             =  64;  /* ADIO_EXCL */
enum MPI_MODE_APPEND           = 128;  /* ADIO_APPEND */
enum MPI_MODE_SEQUENTIAL       = 256;  /* ADIO_SEQUENTIAL */

enum MPI_DISPLACEMENT_CURRENT   = -54278278;

enum MPI_SEEK_SET              = 600;
enum MPI_SEEK_CUR              = 602;
enum MPI_SEEK_END              = 604;

/* Max data representation length */
enum MPI_MAX_DATAREP_STRING = OPAL_MAX_DATAREP_STRING;

}
// #endif /* #if OMPI_PROVIDE_MPI_FILE_INTERFACE */

/*
 * MPI-2 One-Sided Communications asserts
 */
enum MPI_MODE_NOCHECK           = 1;
enum MPI_MODE_NOPRECEDE         = 2;
enum MPI_MODE_NOPUT             = 4;
enum MPI_MODE_NOSTORE           = 8;
enum MPI_MODE_NOSUCCEED         = 16;

enum MPI_LOCK_EXCLUSIVE          = 1;
enum MPI_LOCK_SHARED             = 2;

enum MPI_WIN_FLAVOR_CREATE       = 1;
enum MPI_WIN_FLAVOR_ALLOCATE     = 2;
enum MPI_WIN_FLAVOR_DYNAMIC      = 3;
enum MPI_WIN_FLAVOR_SHARED       = 4;

enum MPI_WIN_UNIFIED             = 0;
enum MPI_WIN_SEPARATE            = 1;

/*
 * Predefined attribute keyvals
 *
 * DO NOT CHANGE THE ORDER WITHOUT ALSO CHANGING THE ORDER IN
 * src/attribute/attribute_predefined.c and mpif.h.in.
 */
enum {
    /* MPI-1 */
    MPI_TAG_UB,
    MPI_HOST,
    MPI_IO,
    MPI_WTIME_IS_GLOBAL,

    /* MPI-2 */
    MPI_APPNUM,
    MPI_LASTUSEDCODE,
    MPI_UNIVERSE_SIZE,
    MPI_WIN_BASE,
    MPI_WIN_SIZE,
    MPI_WIN_DISP_UNIT,
    MPI_WIN_CREATE_FLAVOR,
    MPI_WIN_MODEL,

    /* Even though these four are IMPI attributes, they need to be there
       for all MPI jobs */
    IMPI_CLIENT_SIZE,
    IMPI_CLIENT_COLOR,
    IMPI_HOST_SIZE,
    IMPI_HOST_COLOR
};

/*
 * Error classes and codes
 * Do not change the values of these without also modifying mpif.h.in.
 */
enum MPI_SUCCESS                  = 0;
enum MPI_ERR_BUFFER               = 1;
enum MPI_ERR_COUNT                = 2;
enum MPI_ERR_TYPE                 = 3;
enum MPI_ERR_TAG                  = 4;
enum MPI_ERR_COMM                 = 5;
enum MPI_ERR_RANK                 = 6;
enum MPI_ERR_REQUEST              = 7;
enum MPI_ERR_ROOT                 = 8;
enum MPI_ERR_GROUP                = 9;
enum MPI_ERR_OP                   = 10;
enum MPI_ERR_TOPOLOGY             = 11;
enum MPI_ERR_DIMS                 = 12;
enum MPI_ERR_ARG                  = 13;
enum MPI_ERR_UNKNOWN              = 14;
enum MPI_ERR_TRUNCATE             = 15;
enum MPI_ERR_OTHER                = 16;
enum MPI_ERR_INTERN               = 17;
enum MPI_ERR_IN_STATUS            = 18;
enum MPI_ERR_PENDING              = 19;
enum MPI_ERR_ACCESS               = 20;
enum MPI_ERR_AMODE                = 21;
enum MPI_ERR_ASSERT               = 22;
enum MPI_ERR_BAD_FILE             = 23;
enum MPI_ERR_BASE                 = 24;
enum MPI_ERR_CONVERSION           = 25;
enum MPI_ERR_DISP                 = 26;
enum MPI_ERR_DUP_DATAREP          = 27;
enum MPI_ERR_FILE_EXISTS          = 28;
enum MPI_ERR_FILE_IN_USE          = 29;
enum MPI_ERR_FILE                 = 30;
enum MPI_ERR_INFO_KEY             = 31;
enum MPI_ERR_INFO_NOKEY           = 32;
enum MPI_ERR_INFO_VALUE           = 33;
enum MPI_ERR_INFO                 = 34;
enum MPI_ERR_IO                   = 35;
enum MPI_ERR_KEYVAL               = 36;
enum MPI_ERR_LOCKTYPE             = 37;
enum MPI_ERR_NAME                 = 38;
enum MPI_ERR_NO_MEM               = 39;
enum MPI_ERR_NOT_SAME             = 40;
enum MPI_ERR_NO_SPACE             = 41;
enum MPI_ERR_NO_SUCH_FILE         = 42;
enum MPI_ERR_PORT                 = 43;
enum MPI_ERR_QUOTA                = 44;
enum MPI_ERR_READ_ONLY            = 45;
enum MPI_ERR_RMA_CONFLICT         = 46;
enum MPI_ERR_RMA_SYNC             = 47;
enum MPI_ERR_SERVICE              = 48;
enum MPI_ERR_SIZE                 = 49;
enum MPI_ERR_SPAWN                = 50;
enum MPI_ERR_UNSUPPORTED_DATAREP  = 51;
enum MPI_ERR_UNSUPPORTED_OPERATION = 52;
enum MPI_ERR_WIN                  = 53;
enum MPI_T_ERR_MEMORY             = 54;
enum MPI_T_ERR_NOT_INITIALIZED    = 55;
enum MPI_T_ERR_CANNOT_INIT        = 56;
enum MPI_T_ERR_INVALID_INDEX      = 57;
enum MPI_T_ERR_INVALID_ITEM       = 58;
enum MPI_T_ERR_INVALID_HANDLE     = 59;
enum MPI_T_ERR_OUT_OF_HANDLES     = 60;
enum MPI_T_ERR_OUT_OF_SESSIONS    = 61;
enum MPI_T_ERR_INVALID_SESSION    = 62;
enum MPI_T_ERR_CVAR_SET_NOT_NOW   = 63;
enum MPI_T_ERR_CVAR_SET_NEVER     = 64;
enum MPI_T_ERR_PVAR_NO_STARTSTOP  = 65;
enum MPI_T_ERR_PVAR_NO_WRITE      = 66;
enum MPI_T_ERR_PVAR_NO_ATOMIC     = 67;
enum MPI_ERR_RMA_RANGE            = 68;
enum MPI_ERR_RMA_ATTACH           = 69;
enum MPI_ERR_RMA_FLAVOR           = 70;
enum MPI_ERR_RMA_SHARED           = 71;
enum MPI_T_ERR_INVALID            = 72;
enum MPI_T_ERR_INVALID_NAME       = 73;

/* Per MPI-3 p349 47, MPI_ERR_LASTCODE must be >= the last predefined
   MPI_ERR_<foo> code. Set the last code to allow some room for adding
   error codes without breaking ABI. */
enum MPI_ERR_LASTCODE   =           92;

enum MPI_ERR_SYSRESOURCE =         -2;


/*
 * Comparison results.  Don't change the order of these, the group
 * comparison functions rely on it.
 * Do not change the order of these without also modifying mpif.h.in.
 */
enum {
  MPI_IDENT,
  MPI_CONGRUENT,
  MPI_SIMILAR,
  MPI_UNEQUAL
};

/*
 * MPI_Init_thread constants
 * Do not change the order of these without also modifying mpif.h.in.
 */
enum {
  MPI_THREAD_SINGLE,
  MPI_THREAD_FUNNELED,
  MPI_THREAD_SERIALIZED,
  MPI_THREAD_MULTIPLE
};

/*
 * Datatype combiners.
 * Do not change the order of these without also modifying mpif.h.in.
 * (see also mpif-common.h.fin).
 */
enum {
  MPI_COMBINER_NAMED,
  MPI_COMBINER_DUP,
  MPI_COMBINER_CONTIGUOUS,
  MPI_COMBINER_VECTOR,
  MPI_COMBINER_HVECTOR_INTEGER,
  MPI_COMBINER_HVECTOR,
  MPI_COMBINER_INDEXED,
  MPI_COMBINER_HINDEXED_INTEGER,
  MPI_COMBINER_HINDEXED,
  MPI_COMBINER_INDEXED_BLOCK,
  MPI_COMBINER_STRUCT_INTEGER,
  MPI_COMBINER_STRUCT,
  MPI_COMBINER_SUBARRAY,
  MPI_COMBINER_DARRAY,
  MPI_COMBINER_F90_REAL,
  MPI_COMBINER_F90_COMPLEX,
  MPI_COMBINER_F90_INTEGER,
  MPI_COMBINER_RESIZED,
  MPI_COMBINER_HINDEXED_BLOCK
};

/*
 * Communicator split type constants.
 * Do not change the order of these without also modifying mpif.h.in
 * (see also mpif-common.h.fin).
 */
enum {
  MPI_COMM_TYPE_SHARED
};

/*
 * MPIT Verbosity Levels
 */
enum {
  MPI_T_VERBOSITY_USER_BASIC,
  MPI_T_VERBOSITY_USER_DETAIL,
  MPI_T_VERBOSITY_USER_ALL,
  MPI_T_VERBOSITY_TUNER_BASIC,
  MPI_T_VERBOSITY_TUNER_DETAIL,
  MPI_T_VERBOSITY_TUNER_ALL,
  MPI_T_VERBOSITY_MPIDEV_BASIC,
  MPI_T_VERBOSITY_MPIDEV_DETAIL,
  MPI_T_VERBOSITY_MPIDEV_ALL
};

/*
 * MPIT Scopes
 */
enum {
  MPI_T_SCOPE_CONSTANT,
  MPI_T_SCOPE_READONLY,
  MPI_T_SCOPE_LOCAL,
  MPI_T_SCOPE_GROUP,
  MPI_T_SCOPE_GROUP_EQ,
  MPI_T_SCOPE_ALL,
  MPI_T_SCOPE_ALL_EQ
};

/*
 * MPIT Object Binding
 */
enum {
  MPI_T_BIND_NO_OBJECT,
  MPI_T_BIND_MPI_COMM,
  MPI_T_BIND_MPI_DATATYPE,
  MPI_T_BIND_MPI_ERRHANDLER,
  MPI_T_BIND_MPI_FILE,
  MPI_T_BIND_MPI_GROUP,
  MPI_T_BIND_MPI_OP,
  MPI_T_BIND_MPI_REQUEST,
  MPI_T_BIND_MPI_WIN,
  MPI_T_BIND_MPI_MESSAGE,
  MPI_T_BIND_MPI_INFO
};

/*
 * MPIT pvar classes
 */
enum {
  MPI_T_PVAR_CLASS_STATE,
  MPI_T_PVAR_CLASS_LEVEL,
  MPI_T_PVAR_CLASS_SIZE,
  MPI_T_PVAR_CLASS_PERCENTAGE,
  MPI_T_PVAR_CLASS_HIGHWATERMARK,
  MPI_T_PVAR_CLASS_LOWWATERMARK,
  MPI_T_PVAR_CLASS_COUNTER,
  MPI_T_PVAR_CLASS_AGGREGATE,
  MPI_T_PVAR_CLASS_TIMER,
  MPI_T_PVAR_CLASS_GENERIC
};

// MPI_Status is a structure, but size may be implementation dependent

struct MPI_Status {
  // Three public members 
  int MPI_SOURCE;
  int MPI_TAG;
  int MPI_ERROR;
  // Additional fields for implementation's use
  int [10] reserved; // Make bigger than needed just in case
}

// MPI_Aint not yet defined so some functions missing

//////////////////////////////////////////////////////////////////////
// MPI external functions
// Define the MPI interface
extern(C) {
  int MPI_Abort(MPI_Comm comm, int errorcode);
  
  /*
  int MPI_Accumulate(void *origin_addr, int origin_count, MPI_Datatype origin_datatype,
                     int target_rank, MPI_Aint target_disp, int target_count,
                     MPI_Datatype target_datatype, MPI_Op op, MPI_Win win); 
  */
  
  int MPI_Add_error_class(int *errorclass);
  int MPI_Add_error_code(int errorclass, int *errorcode);
  int MPI_Add_error_string(int errorcode, char *string);
  
  //int MPI_Address(void *location, MPI_Aint *address); // Depreciated
  
  int MPI_Allgather(void *sendbuf, int sendcount, MPI_Datatype sendtype, 
                    void *recvbuf, int recvcount, 
                    MPI_Datatype recvtype, MPI_Comm comm);
  int MPI_Allgatherv(void *sendbuf, int sendcount, MPI_Datatype sendtype, 
                     void *recvbuf, int *recvcounts, 
                     int *displs, MPI_Datatype recvtype, MPI_Comm comm);
  
  //int MPI_Alloc_mem(MPI_Aint size, MPI_Info info, void *baseptr);
  
  int MPI_Allreduce(void *sendbuf, void *recvbuf, int count, 
                    MPI_Datatype datatype, MPI_Op op, MPI_Comm comm); 
  int MPI_Alltoall(void *sendbuf, int sendcount, MPI_Datatype sendtype, 
                   void *recvbuf, int recvcount, 
                   MPI_Datatype recvtype, MPI_Comm comm);
  int MPI_Alltoallv(void *sendbuf, int *sendcounts, int *sdispls, 
                    MPI_Datatype sendtype, void *recvbuf, int *recvcounts,
                    int *rdispls, MPI_Datatype recvtype, MPI_Comm comm);
  int MPI_Alltoallw(void *sendbuf, int *sendcounts, int *sdispls, MPI_Datatype *sendtypes, 
                    void *recvbuf, int *recvcounts, int *rdispls, MPI_Datatype *recvtypes,
                    MPI_Comm comm);
  int MPI_Attr_delete(MPI_Comm comm, int keyval);
  int MPI_Attr_get(MPI_Comm comm, int keyval, void *attribute_val, int *flag);
  int MPI_Attr_put(MPI_Comm comm, int keyval, void *attribute_val);
  int MPI_Barrier(MPI_Comm comm);
  int MPI_Bcast(void *buffer, int count, MPI_Datatype datatype, int root, MPI_Comm comm);
  int MPI_Bsend(void *buf, int count, MPI_Datatype datatype, int dest, int tag, MPI_Comm comm);
  int MPI_Bsend_init(void *buf, int count, MPI_Datatype datatype, 
                     int dest, int tag, MPI_Comm comm, MPI_Request *request); 
  int MPI_Buffer_attach(void *buffer, int size);
  int MPI_Buffer_detach(void *buffer, int *size);
  int MPI_Cancel(MPI_Request *request);
  int MPI_Cart_coords(MPI_Comm comm, int rank, int maxdims, int *coords);
  int MPI_Cart_create(MPI_Comm old_comm, int ndims, int *dims, 
                      int *periods, int reorder, MPI_Comm *comm_cart);
  int MPI_Cart_get(MPI_Comm comm, int maxdims, int *dims, int *periods, int *coords);
  int MPI_Cart_map(MPI_Comm comm, int ndims, int *dims, 
                   int *periods, int *newrank);
  int MPI_Cart_rank(MPI_Comm comm, int *coords, int *rank);
  int MPI_Cart_shift(MPI_Comm comm, int direction, int disp, 
                     int *rank_source, int *rank_dest);
  int MPI_Cart_sub(MPI_Comm comm, int *remain_dims, MPI_Comm *new_comm);
  int MPI_Cartdim_get(MPI_Comm comm, int *ndims);
  int MPI_Close_port(char *port_name);
  int MPI_Comm_accept(char *port_name, MPI_Info info, int root, 
                      MPI_Comm comm, MPI_Comm *newcomm);
  //MPI_Fint MPI_Comm_c2f(MPI_Comm comm);
  int MPI_Comm_call_errhandler(MPI_Comm comm, int errorcode);
  int MPI_Comm_compare(MPI_Comm comm1, MPI_Comm comm2, int *result);
  int MPI_Comm_connect(char *port_name, MPI_Info info, int root, 
                       MPI_Comm comm, MPI_Comm *newcomm);
  //int MPI_Comm_create_errhandler(MPI_Comm_errhandler_fn *function, MPI_Errhandler *errhandler);
  /*
  int MPI_Comm_create_keyval(MPI_Comm_copy_attr_function *comm_copy_attr_fn, 
                             MPI_Comm_delete_attr_function *comm_delete_attr_fn, 
                             int *comm_keyval, void *extra_state);
  */
  int MPI_Comm_create(MPI_Comm comm, MPI_Group group, MPI_Comm *newcomm);
  int MPI_Comm_delete_attr(MPI_Comm comm, int comm_keyval);
  int MPI_Comm_disconnect(MPI_Comm *comm);
  int MPI_Comm_dup(MPI_Comm comm, MPI_Comm *newcomm);
  //MPI_Comm MPI_Comm_f2c(MPI_Fint comm);
  int MPI_Comm_free_keyval(int *comm_keyval);
  int MPI_Comm_free(MPI_Comm *comm);
  int MPI_Comm_get_attr(MPI_Comm comm, int comm_keyval, 
                        void *attribute_val, int *flag);
  //int MPI_Comm_get_errhandler(MPI_Comm comm, MPI_Errhandler *erhandler);
  int MPI_Comm_get_name(MPI_Comm comm, char *comm_name, int *resultlen);
  int MPI_Comm_get_parent(MPI_Comm *parent);
  int MPI_Comm_group(MPI_Comm comm, MPI_Group *group);
  int MPI_Comm_join(int fd, MPI_Comm *intercomm);
  int MPI_Comm_rank(MPI_Comm comm, int *rank);
  int MPI_Comm_remote_group(MPI_Comm comm, MPI_Group *group);
  int MPI_Comm_remote_size(MPI_Comm comm, int *size);
  int MPI_Comm_set_attr(MPI_Comm comm, int comm_keyval, void *attribute_val);
  //int MPI_Comm_set_errhandler(MPI_Comm comm, MPI_Errhandler errhandler);
  int MPI_Comm_set_name(MPI_Comm comm, char *comm_name);
  int MPI_Comm_size(MPI_Comm comm, int *size);
  int MPI_Comm_spawn(char *command, char **argv, int maxprocs, MPI_Info info, 
                     int root, MPI_Comm comm, MPI_Comm *intercomm, 
                     int *array_of_errcodes);
  int MPI_Comm_spawn_multiple(int count, char **array_of_commands, char ***array_of_argv, 
                              int *array_of_maxprocs, MPI_Info *array_of_info, 
                              int root, MPI_Comm comm, MPI_Comm *intercomm, 
                              int *array_of_errcodes);
  int MPI_Comm_split(MPI_Comm comm, int color, int key, MPI_Comm *newcomm);
  int MPI_Comm_test_inter(MPI_Comm comm, int *flag);
  int MPI_Dims_create(int nnodes, int ndims, int *dims);
  //MPI_Fint MPI_Errhandler_c2f(MPI_Errhandler errhandler);
  //int MPI_Errhandler_create(MPI_Handler_function *function, MPI_Errhandler *errhandler);
  //MPI_Errhandler MPI_Errhandler_f2c(MPI_Fint errhandler);
  //int MPI_Errhandler_free(MPI_Errhandler *errhandler);
  //int MPI_Errhandler_get(MPI_Comm comm, MPI_Errhandler *errhandler);
  //int MPI_Errhandler_set(MPI_Comm comm, MPI_Errhandler errhandler);
  int MPI_Error_class(int errorcode, int *errorclass);
  int MPI_Error_string(int errorcode, char *string, int *resultlen);
  int MPI_Exscan(void *sendbuf, void *recvbuf, int count, 
                 MPI_Datatype datatype, MPI_Op op, MPI_Comm comm);
  
  
  int MPI_Finalize();
  int MPI_Finalized(int *flag);
  int MPI_Free_mem(void *base);
  int MPI_Gather(void *sendbuf, int sendcount, MPI_Datatype sendtype, 
                 void *recvbuf, int recvcount, MPI_Datatype recvtype, 
                 int root, MPI_Comm comm);
  int MPI_Gatherv(void *sendbuf, int sendcount, MPI_Datatype sendtype, 
                  void *recvbuf, int *recvcounts, int *displs, 
                  MPI_Datatype recvtype, int root, MPI_Comm comm);
  //int MPI_Get_address(void *location, MPI_Aint *address);
  int MPI_Get_count(MPI_Status *status, MPI_Datatype datatype, int *count);
  int MPI_Get_elements(MPI_Status *status, MPI_Datatype datatype, int *count);
  /*
  int MPI_Get(void *origin_addr, int origin_count, 
              MPI_Datatype origin_datatype, int target_rank, 
              MPI_Aint target_disp, int target_count, 
              MPI_Datatype target_datatype, MPI_Win win);
  */
  int MPI_Get_processor_name(char *name, int *resultlen);
  int MPI_Get_version(int *ver, int *subversion);
  int MPI_Graph_create(MPI_Comm comm_old, int nnodes, int *index, 
                       int *edges, int reorder, MPI_Comm *comm_graph);
  int MPI_Graph_get(MPI_Comm comm, int maxindex, int maxedges, 
                    int *index, int *edges);
  int MPI_Graph_map(MPI_Comm comm, int nnodes, int *index, int *edges, 
                    int *newrank);
  int MPI_Graph_neighbors_count(MPI_Comm comm, int rank, int *nneighbors);
  int MPI_Graph_neighbors(MPI_Comm comm, int rank, int maxneighbors, 
                          int *neighbors);
  int MPI_Graphdims_get(MPI_Comm comm, int *nnodes, int *nedges);
  int MPI_Grequest_complete(MPI_Request request);
  /*
  int MPI_Grequest_start(MPI_Grequest_query_function *query_fn,
                         MPI_Grequest_free_function *free_fn,
                         MPI_Grequest_cancel_function *cancel_fn,
                         void *extra_state, MPI_Request *request);
  */
  //MPI_Fint MPI_Group_c2f(MPI_Group group);
  int MPI_Group_compare(MPI_Group group1, MPI_Group group2, int *result);
  int MPI_Group_difference(MPI_Group group1, MPI_Group group2, 
                           MPI_Group *newgroup);
  int MPI_Group_excl(MPI_Group group, int n, int *ranks, 
                     MPI_Group *newgroup);
  //MPI_Group MPI_Group_f2c(MPI_Fint group);
  int MPI_Group_free(MPI_Group *group);
  int MPI_Group_incl(MPI_Group group, int n, int *ranks, 
                     MPI_Group *newgroup);
  int MPI_Group_intersection(MPI_Group group1, MPI_Group group2, 
                             MPI_Group *newgroup);
  int MPI_Group_range_excl(MPI_Group group, int n, int [][3] ranges, 
                           MPI_Group *newgroup);
  int MPI_Group_range_incl(MPI_Group group, int n, int [][3] ranges, 
                           MPI_Group *newgroup);
  int MPI_Group_rank(MPI_Group group, int *rank);
  int MPI_Group_size(MPI_Group group, int *size);
  int MPI_Group_translate_ranks(MPI_Group group1, int n, int *ranks1, 
                                MPI_Group group2, int *ranks2);
  int MPI_Group_union(MPI_Group group1, MPI_Group group2, 
                      MPI_Group *newgroup);
  int MPI_Ibsend(void *buf, int count, MPI_Datatype datatype, int dest, 
                 int tag, MPI_Comm comm, MPI_Request *request);
  //MPI_Fint MPI_Info_c2f(MPI_Info info);
  int MPI_Info_create(MPI_Info *info);
  int MPI_Info_delete(MPI_Info info, char *key);
  int MPI_Info_dup(MPI_Info info, MPI_Info *newinfo);
  //MPI_Info MPI_Info_f2c(MPI_Fint info);
  int MPI_Info_free(MPI_Info *info);
  int MPI_Info_get(MPI_Info info, char *key, int valuelen, 
                   char *value, int *flag);
  int MPI_Info_get_nkeys(MPI_Info info, int *nkeys);
  int MPI_Info_get_nthkey(MPI_Info info, int n, char *key);
  int MPI_Info_get_valuelen(MPI_Info info, char *key, int *valuelen, 
                            int *flag);
  int MPI_Info_set(MPI_Info info, char *key, char *value);
  int MPI_Init(int *argc, char ***argv);
  int MPI_Initialized(int *flag);
  int MPI_Init_thread(int *argc, char ***argv, int required, 
                      int *provided);
  int MPI_Intercomm_create(MPI_Comm local_comm, int local_leader, 
                           MPI_Comm bridge_comm, int remote_leader, 
                           int tag, MPI_Comm *newintercomm);
  int MPI_Intercomm_merge(MPI_Comm intercomm, int high, 
                          MPI_Comm *newintercomm);
  int MPI_Iprobe(int source, int tag, MPI_Comm comm, int *flag, 
                 MPI_Status *status);
  int MPI_Irecv(void *buf, int count, MPI_Datatype datatype, int source, 
                int tag, MPI_Comm comm, MPI_Request *request);
  int MPI_Irsend(void *buf, int count, MPI_Datatype datatype, int dest, 
                 int tag, MPI_Comm comm, MPI_Request *request);
  int MPI_Isend(void *buf, int count, MPI_Datatype datatype, int dest, 
                int tag, MPI_Comm comm, MPI_Request *request);
  int MPI_Issend(void *buf, int count, MPI_Datatype datatype, int dest, 
                 int tag, MPI_Comm comm, MPI_Request *request);
  int MPI_Is_thread_main(int *flag);
  /*
  int MPI_Keyval_create(MPI_Copy_function *copy_fn, 
                        MPI_Delete_function *delete_fn, 
                        int *keyval, void *extra_state);
  */
  int MPI_Keyval_free(int *keyval);
  int MPI_Lookup_name(char *service_name, MPI_Info info, char *port_name);
  //MPI_Fint MPI_Op_c2f(MPI_Op op); 
  //int MPI_Op_create(MPI_User_function *function, int commute, MPI_Op *op);
  int MPI_Open_port(MPI_Info info, char *port_name);
  //MPI_Op MPI_Op_f2c(MPI_Fint op);
  int MPI_Op_free(MPI_Op *op);
  /*
  int MPI_Pack_external(char *datarep, void *inbuf, int incount,
                        MPI_Datatype datatype, void *outbuf,
                        MPI_Aint outsize, MPI_Aint *position);
  */
  /*
  int MPI_Pack_external_size(char *datarep, int incount, 
                             MPI_Datatype datatype, MPI_Aint *size);
  */
  int MPI_Pack(void *inbuf, int incount, MPI_Datatype datatype, 
               void *outbuf, int outsize, int *position, MPI_Comm comm);
  int MPI_Pack_size(int incount, MPI_Datatype datatype, MPI_Comm comm, 
                    int *size);
  int MPI_Pcontrol(const int level, ...);
  int MPI_Probe(int source, int tag, MPI_Comm comm, MPI_Status *status);
  int MPI_Publish_name(char *service_name, MPI_Info info, 
                       char *port_name);
  /*
  int MPI_Put(void *origin_addr, int origin_count, MPI_Datatype origin_datatype, 
              int target_rank, MPI_Aint target_disp, int target_count, 
              MPI_Datatype target_datatype, MPI_Win win);
  */
  int MPI_Query_thread(int *provided);
  int MPI_Recv_init(void *buf, int count, MPI_Datatype datatype, int source,
                    int tag, MPI_Comm comm, MPI_Request *request);
  int MPI_Recv(void *buf, int count, MPI_Datatype datatype, int source, 
               int tag, MPI_Comm comm, MPI_Status *status);
  int MPI_Reduce(void *sendbuf, void *recvbuf, int count, 
                 MPI_Datatype datatype, MPI_Op op, int root, MPI_Comm comm);
  int MPI_Reduce_scatter(void *sendbuf, void *recvbuf, int *recvcounts, 
                         MPI_Datatype datatype, MPI_Op op, MPI_Comm comm);
  /*
  int MPI_Register_datarep(char *datarep, 
                           MPI_Datarep_conversion_function *read_conversion_fn,
                           MPI_Datarep_conversion_function *write_conversion_fn,
                           MPI_Datarep_extent_function *dtype_file_extent_fn,
                           void *extra_state);
  */
  //MPI_Fint MPI_Request_c2f(MPI_Request request);
  //MPI_Request MPI_Request_f2c(MPI_Fint request);
  int MPI_Request_free(MPI_Request *request);
  int MPI_Request_get_status(MPI_Request request, int *flag, 
                             MPI_Status *status);
  int MPI_Rsend(void *ibuf, int count, MPI_Datatype datatype, int dest, 
                int tag, MPI_Comm comm);
  int MPI_Rsend_init(void *buf, int count, MPI_Datatype datatype, 
                     int dest, int tag, MPI_Comm comm, 
                     MPI_Request *request);
  int MPI_Scan(void *sendbuf, void *recvbuf, int count, 
               MPI_Datatype datatype, MPI_Op op, MPI_Comm comm);
  int MPI_Scatter(void *sendbuf, int sendcount, MPI_Datatype sendtype, 
                  void *recvbuf, int recvcount, MPI_Datatype recvtype, 
                  int root, MPI_Comm comm);
  int MPI_Scatterv(void *sendbuf, int *sendcounts, int *displs, 
                   MPI_Datatype sendtype, void *recvbuf, int recvcount, 
                   MPI_Datatype recvtype, int root, MPI_Comm comm);
  int MPI_Send_init(void *buf, int count, MPI_Datatype datatype, 
                    int dest, int tag, MPI_Comm comm, 
                    MPI_Request *request);
  int MPI_Send(void *buf, int count, MPI_Datatype datatype, int dest, 
               int tag, MPI_Comm comm);
  int MPI_Sendrecv(void *sendbuf, int sendcount, MPI_Datatype sendtype, 
                   int dest, int sendtag, void *recvbuf, int recvcount,
                   MPI_Datatype recvtype, int source, int recvtag, 
                   MPI_Comm comm,  MPI_Status *status);
  int MPI_Sendrecv_replace(void * buf, int count, MPI_Datatype datatype, 
                           int dest, int sendtag, int source, int recvtag,
                           MPI_Comm comm, MPI_Status *status);
  int MPI_Ssend_init(void *buf, int count, MPI_Datatype datatype, 
                     int dest, int tag, MPI_Comm comm, 
                     MPI_Request *request);
  int MPI_Ssend(void *buf, int count, MPI_Datatype datatype, int dest, 
                int tag, MPI_Comm comm);
  int MPI_Start(MPI_Request *request);
  int MPI_Startall(int count, MPI_Request *array_of_requests);
  //int MPI_Status_c2f(MPI_Status *c_status, MPI_Fint *f_status);
  //int MPI_Status_f2c(MPI_Fint *f_status, MPI_Status *c_status);
  int MPI_Status_set_cancelled(MPI_Status *status, int flag);
  int MPI_Status_set_elements(MPI_Status *status, MPI_Datatype datatype,
                              int count);
  int MPI_Testall(int count, MPI_Request [] array_of_requests, int *flag, 
                  MPI_Status [] array_of_statuses);
  int MPI_Testany(int count, MPI_Request [] array_of_requests, int *index, 
                  int *flag, MPI_Status *status);
  int MPI_Test(MPI_Request *request, int *flag, MPI_Status *status);
  int MPI_Test_cancelled(MPI_Status *status, int *flag);
  int MPI_Testsome(int incount, MPI_Request [] array_of_requests, 
                   int *outcount, int [] array_of_indices, 
                   MPI_Status [] array_of_statuses);
  int MPI_Topo_test(MPI_Comm comm, int *status);
  //MPI_Fint MPI_Type_c2f(MPI_Datatype datatype);
  int MPI_Type_commit(MPI_Datatype *type);
  int MPI_Type_contiguous(int count, MPI_Datatype oldtype, 
                          MPI_Datatype *newtype);
  int MPI_Type_create_darray(int size, int rank, int ndims, 
                             int [] gsize_array, int [] distrib_array, 
                             int [] darg_array, int [] psize_array,
                             int order, MPI_Datatype oldtype, 
                             MPI_Datatype *newtype);
  int MPI_Type_create_f90_complex(int p, int r, MPI_Datatype *newtype);
  int MPI_Type_create_f90_integer(int r, MPI_Datatype *newtype);
  int MPI_Type_create_f90_real(int p, int r, MPI_Datatype *newtype);
  /*
  int MPI_Type_create_hindexed(int count, int array_of_blocklengths[], 
                               MPI_Aint array_of_displacements[], 
                               MPI_Datatype oldtype, 
                               MPI_Datatype *newtype);
  */
  /*
  int MPI_Type_create_hvector(int count, int blocklength, MPI_Aint stride, 
                              MPI_Datatype oldtype, 
                              MPI_Datatype *newtype);
  */
  /*
  int MPI_Type_create_keyval(MPI_Type_copy_attr_function *type_copy_attr_fn, 
                             MPI_Type_delete_attr_function *type_delete_attr_fn, 
                             int *type_keyval, void *extra_state);
  */
  int MPI_Type_create_indexed_block(int count, int blocklength,
                                    int [] array_of_displacements,
                                    MPI_Datatype oldtype,
                                    MPI_Datatype *newtype);
  /*
  int MPI_Type_create_struct(int count, int array_of_block_lengths[], 
                             MPI_Aint array_of_displacements[], 
                             MPI_Datatype array_of_types[], 
                             MPI_Datatype *newtype);
  */
  int MPI_Type_create_subarray(int ndims, int [] size_array, int [] subsize_array, 
                               int [] start_array, int order, 
                               MPI_Datatype oldtype, MPI_Datatype *newtype);
  /*
  int MPI_Type_create_resized(MPI_Datatype oldtype, MPI_Aint lb, 
                              MPI_Aint extent, MPI_Datatype *newtype); 
  */
  int MPI_Type_delete_attr(MPI_Datatype type, int type_keyval);
  int MPI_Type_dup(MPI_Datatype type, MPI_Datatype *newtype);
  //int MPI_Type_extent(MPI_Datatype type, MPI_Aint *extent);
  int MPI_Type_free(MPI_Datatype *type);
  int MPI_Type_free_keyval(int *type_keyval);
  //MPI_Datatype MPI_Type_f2c(MPI_Fint datatype);
  int MPI_Type_get_attr(MPI_Datatype type, int type_keyval, 
                        void *attribute_val, int *flag);
  /*
  int MPI_Type_get_contents(MPI_Datatype mtype, int max_integers, 
                            int max_addresses, int max_datatypes, 
                            int array_of_integers[], 
                            MPI_Aint array_of_addresses[], 
                            MPI_Datatype array_of_datatypes[]);
  */
  int MPI_Type_get_envelope(MPI_Datatype type, int *num_integers, 
                            int *num_addresses, int *num_datatypes, 
                            int *combiner);
  //int MPI_Type_get_extent(MPI_Datatype type, MPI_Aint *lb, MPI_Aint *extent);
  int MPI_Type_get_name(MPI_Datatype type, char *type_name, 
                        int *resultlen);
  //int MPI_Type_get_true_extent(MPI_Datatype datatype, MPI_Aint *true_lb, MPI_Aint *true_extent);
  /*
  int MPI_Type_hindexed(int count, int array_of_blocklengths[], 
                        MPI_Aint array_of_displacements[], 
                        MPI_Datatype oldtype, MPI_Datatype *newtype);
  */
  /*
  int MPI_Type_hvector(int count, int blocklength, MPI_Aint stride, 
                       MPI_Datatype oldtype, MPI_Datatype *newtype);
  */
  int MPI_Type_indexed(int count, int [] array_of_blocklengths, 
                       int [] array_of_displacements, 
                       MPI_Datatype oldtype, MPI_Datatype *newtype);
  
  //int MPI_Type_lb(MPI_Datatype type, MPI_Aint *lb);
  int MPI_Type_match_size(int typeclass, int size, MPI_Datatype *type);
  int MPI_Type_set_attr(MPI_Datatype type, int type_keyval, 
                        void *attr_val);
  int MPI_Type_set_name(MPI_Datatype type, char *type_name);
  int MPI_Type_size(MPI_Datatype type, int *size);
  /*
  int MPI_Type_struct(int count, int array_of_blocklengths[], 
                      MPI_Aint array_of_displacements[], 
                      MPI_Datatype array_of_types[], 
                      MPI_Datatype *newtype);
  */
  //int MPI_Type_ub(MPI_Datatype mtype, MPI_Aint *ub);
  int MPI_Type_vector(int count, int blocklength, int stride, 
                      MPI_Datatype oldtype, MPI_Datatype *newtype);
  int MPI_Unpack(void *inbuf, int insize, int *position, 
                 void *outbuf, int outcount, MPI_Datatype datatype, 
                 MPI_Comm comm);
  int MPI_Unpublish_name(char *service_name, MPI_Info info, char *port_name);
  /*
  int MPI_Unpack_external (char *datarep, void *inbuf, MPI_Aint insize,
                           MPI_Aint *position, void *outbuf, int outcount,
                           MPI_Datatype datatype);
  */
  int MPI_Waitall(int count, MPI_Request *array_of_requests, 
                  MPI_Status *array_of_statuses);
  int MPI_Waitany(int count, MPI_Request *array_of_requests, 
                  int *index, MPI_Status *status);
  int MPI_Wait(MPI_Request *request, MPI_Status *status);
  int MPI_Waitsome(int incount, MPI_Request *array_of_requests, 
                   int *outcount, int *array_of_indices, 
                   MPI_Status *array_of_statuses);
  //MPI_Fint MPI_Win_c2f(MPI_Win win);
  int MPI_Win_call_errhandler(MPI_Win win, int errorcode);
  int MPI_Win_complete(MPI_Win win);
  /*
  int MPI_Win_create(void *base, MPI_Aint size, int disp_unit, 
                     MPI_Info info, MPI_Comm comm, MPI_Win *win);
  */
  /*
  int MPI_Win_create_errhandler(MPI_Win_errhandler_fn *function, 
                                MPI_Errhandler *errhandler);
  */
  /*
  int MPI_Win_create_keyval(MPI_Win_copy_attr_function *win_copy_attr_fn, 
                            MPI_Win_delete_attr_function *win_delete_attr_fn, 
                            int *win_keyval, void *extra_state);
  */
  int MPI_Win_delete_attr(MPI_Win win, int win_keyval);
  //MPI_Win MPI_Win_f2c(MPI_Fint win);
  int MPI_Win_fence(int asser, MPI_Win win);
  int MPI_Win_free(MPI_Win *win);
  int MPI_Win_free_keyval(int *win_keyval);
  int MPI_Win_get_attr(MPI_Win win, int win_keyval, 
                       void *attribute_val, int *flag);
  int MPI_Win_get_errhandler(MPI_Win win, MPI_Errhandler *errhandler);
  int MPI_Win_get_group(MPI_Win win, MPI_Group *group);
  int MPI_Win_get_name(MPI_Win win, char *win_name, int *resultlen);
  int MPI_Win_lock(int lock_type, int rank, int asser, MPI_Win win);
  int MPI_Win_post(MPI_Group group, int asser, MPI_Win win);
  int MPI_Win_set_attr(MPI_Win win, int win_keyval, void *attribute_val);
  int MPI_Win_set_errhandler(MPI_Win win, MPI_Errhandler errhandler);
  int MPI_Win_set_name(MPI_Win win, char *win_name);
  int MPI_Win_start(MPI_Group group, int asser, MPI_Win win);
  int MPI_Win_test(MPI_Win win, int *flag);
  int MPI_Win_unlock(int rank, MPI_Win win);
  int MPI_Win_wait(MPI_Win win);
  double MPI_Wtick();
  double MPI_Wtime();
}

//////////////////////////////////////////////////////////////////////
// MPI wrapper functions to get predefined handles like MPI_COMM_WORLD
//
// Done this way as different MPI implementations use different means
// to define these quantities e.g. macros. This lacks something in elegance,
// but is more portable between MPI implementations

// Communicators
MPI_Comm MPI_COMM_WORLD, MPI_COMM_SELF;
extern(C) {
  MPI_Comm mpiwrap_get_mpi_comm_world();
  MPI_Comm mpiwrap_get_mpi_comm_self();
}

// Data types
MPI_Datatype MPI_DATATYPE_NULL, MPI_BYTE, MPI_PACKED, MPI_CHAR, MPI_SHORT, MPI_INT, MPI_LONG;
MPI_Datatype MPI_FLOAT, MPI_DOUBLE;
MPI_Datatype MPI_UNSIGNED_CHAR, MPI_UNSIGNED_SHORT, MPI_UNSIGNED_LONG;

extern(C) {
  MPI_Datatype mpiwrap_get_mpi_datatype_null();
  MPI_Datatype mpiwrap_get_mpi_byte();
  MPI_Datatype mpiwrap_get_mpi_packed();
  MPI_Datatype mpiwrap_get_mpi_char();
  MPI_Datatype mpiwrap_get_mpi_short();
  MPI_Datatype mpiwrap_get_mpi_int();
  MPI_Datatype mpiwrap_get_mpi_long();
  MPI_Datatype mpiwrap_get_mpi_float();
  MPI_Datatype mpiwrap_get_mpi_double();
  MPI_Datatype mpiwrap_get_mpi_unsigned_char();
  MPI_Datatype mpiwrap_get_mpi_unsigned_short();
  MPI_Datatype mpiwrap_get_mpi_unsigned_long();
}

// Operations
MPI_Op MPI_MAX, MPI_MIN, MPI_SUM, MPI_PROD;
MPI_Op MPI_LAND, MPI_BAND, MPI_LOR, MPI_BOR, MPI_LXOR, MPI_BXOR;
MPI_Op MPI_MAXLOC, MPI_MINLOC, MPI_REPLACE, MPI_STATUS_IGNORE;
MPI_Op MPI_INFO_NULL;

extern(C) {
  MPI_Op mpiwrap_get_mpi_max();
  MPI_Op mpiwrap_get_mpi_min();
  MPI_Op mpiwrap_get_mpi_sum();
  MPI_Op mpiwrap_get_mpi_prod();
  MPI_Op mpiwrap_get_mpi_land();
  MPI_Op mpiwrap_get_mpi_band();
  MPI_Op mpiwrap_get_mpi_lor();
  MPI_Op mpiwrap_get_mpi_bor();
  MPI_Op mpiwrap_get_mpi_lxor();
  MPI_Op mpiwrap_get_mpi_bxor();
  MPI_Op mpiwrap_get_mpi_maxloc();
  MPI_Op mpiwrap_get_mpi_minloc();
  MPI_Op mpiwrap_get_mpi_replace();
  MPI_Op mpiwrap_get_mpi_status_ignore ();
  MPI_Op mpiwrap_get_mpi_info_null ();
}

// Call this to set global variables
void MPI_Get_globals() {
  MPI_COMM_WORLD     = mpiwrap_get_mpi_comm_world();
  MPI_COMM_SELF      = mpiwrap_get_mpi_comm_self();
  
  MPI_DATATYPE_NULL  = mpiwrap_get_mpi_datatype_null();
  MPI_BYTE           = mpiwrap_get_mpi_byte();
  MPI_PACKED         = mpiwrap_get_mpi_packed();
  MPI_CHAR           = mpiwrap_get_mpi_char();
  MPI_SHORT          = mpiwrap_get_mpi_short();
  MPI_INT            = mpiwrap_get_mpi_int();
  MPI_LONG           = mpiwrap_get_mpi_long();
  MPI_FLOAT          = mpiwrap_get_mpi_float();
  MPI_DOUBLE         = mpiwrap_get_mpi_double();
  MPI_UNSIGNED_CHAR  = mpiwrap_get_mpi_unsigned_char();
  MPI_UNSIGNED_SHORT = mpiwrap_get_mpi_unsigned_short();
  MPI_UNSIGNED_LONG  = mpiwrap_get_mpi_unsigned_long();

  MPI_MAX     = mpiwrap_get_mpi_max();
  MPI_MIN     = mpiwrap_get_mpi_min();
  MPI_SUM     = mpiwrap_get_mpi_sum();
  MPI_PROD    = mpiwrap_get_mpi_prod();
  MPI_LAND    = mpiwrap_get_mpi_land();
  MPI_BAND    = mpiwrap_get_mpi_band();
  MPI_LOR     = mpiwrap_get_mpi_lor();
  MPI_BOR     = mpiwrap_get_mpi_bor();
  MPI_LXOR    = mpiwrap_get_mpi_lxor();
  MPI_BXOR    = mpiwrap_get_mpi_bxor();
  MPI_MAXLOC  = mpiwrap_get_mpi_maxloc();
  MPI_MINLOC  = mpiwrap_get_mpi_minloc();
  MPI_REPLACE = mpiwrap_get_mpi_replace();
  MPI_STATUS_IGNORE = mpiwrap_get_mpi_status_ignore ();
  MPI_INFO_NULL = mpiwrap_get_mpi_info_null ();
}

//////////////////////////////////////////////////////////////////////
// Wrapper functions to avoid use of pointers and convert
// error codes to exceptions

void MPI_Init(string[] args) {
    import std.conv, std.stdio;
    import core.stdc.stdio;
    import std.datetime;
    
    // Convert arguments to C form
    auto argc = to!int(args.length);    
    char *[] argv = new char *[argc];   
    for (int it = 0; it < argc; it ++) {
	argv [it] = args [it].toStringz [0 .. args [it].length + 1].dup.ptr;
    }
    
    auto aux = argv.ptr;
    // Call C function
    auto begin = Clock.currTime ();
    if( MPI_Init(&argc, &aux) ) {
	// Convert error code to an exception
	throw new Exception("Failed to initialise MPI");
    }
    writeln ("Init a pris ", Clock.currTime - begin);
    // Set globals
    MPI_Get_globals();
}

int MPI_Comm_rank(MPI_Comm comm) {
  int rank;
  if(  MPI_Comm_rank(comm, &rank) ) {
    throw new Exception("MPI_Comm_rank failed");
  }
  return rank;
}

int MPI_Comm_size(MPI_Comm comm) {
  int size;
  if(  MPI_Comm_size(comm, &size) ) {
    throw new Exception("MPI_Comm_size failed");
  }
  return size;
}

