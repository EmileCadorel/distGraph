#include <mpi.h>
// Communication handles

MPI_Comm mpiwrap_get_mpi_comm_world() { return MPI_COMM_WORLD; }
MPI_Comm mpiwrap_get_mpi_comm_self()  { return MPI_COMM_SELF;  }

// Data types
MPI_Datatype mpiwrap_get_mpi_datatype_null()  { return MPI_DATATYPE_NULL;  }
MPI_Datatype mpiwrap_get_mpi_byte()           { return MPI_BYTE;           }
MPI_Datatype mpiwrap_get_mpi_packed()         { return MPI_PACKED;         }
MPI_Datatype mpiwrap_get_mpi_char()           { return MPI_CHAR;           }
MPI_Datatype mpiwrap_get_mpi_short()          { return MPI_SHORT;          }
MPI_Datatype mpiwrap_get_mpi_int()            { return MPI_INT;            }
MPI_Datatype mpiwrap_get_mpi_long()           { return MPI_LONG;           }
MPI_Datatype mpiwrap_get_mpi_float()          { return MPI_FLOAT;          }
MPI_Datatype mpiwrap_get_mpi_double()         { return MPI_DOUBLE;         }
MPI_Datatype mpiwrap_get_mpi_unsigned_char()  { return MPI_UNSIGNED_CHAR;  }
MPI_Datatype mpiwrap_get_mpi_unsigned_short() { return MPI_UNSIGNED_SHORT; }
MPI_Datatype mpiwrap_get_mpi_unsigned_long()  { return MPI_UNSIGNED_LONG;  }

// Operations
MPI_Op mpiwrap_get_mpi_max()     { return MPI_MAX;     }
MPI_Op mpiwrap_get_mpi_min()     { return MPI_MIN;     }
MPI_Op mpiwrap_get_mpi_sum()     { return MPI_SUM;     }
MPI_Op mpiwrap_get_mpi_prod()    { return MPI_PROD;    }
MPI_Op mpiwrap_get_mpi_land()    { return MPI_LAND;    }
MPI_Op mpiwrap_get_mpi_band()    { return MPI_BAND;    }
MPI_Op mpiwrap_get_mpi_lor()     { return MPI_LOR;     }
MPI_Op mpiwrap_get_mpi_bor()     { return MPI_BOR;     }
MPI_Op mpiwrap_get_mpi_lxor()    { return MPI_LXOR;    }
MPI_Op mpiwrap_get_mpi_bxor()    { return MPI_BXOR;    }
MPI_Op mpiwrap_get_mpi_maxloc()  { return MPI_MAXLOC;  }
MPI_Op mpiwrap_get_mpi_minloc()  { return MPI_MINLOC;  }
MPI_Op mpiwrap_get_mpi_replace() { return MPI_REPLACE; }
MPI_Op mpiwrap_get_mpi_status_ignore () { return MPI_STATUS_IGNORE; }
MPI_Op mpiwrap_get_mpi_errcodes_ignore () { return MPI_ERRCODES_IGNORE; }
MPI_Op mpiwrap_get_mpi_info_null () { return MPI_INFO_NULL; }
MPI_Op mpiwrap_get_mpi_argv_null () { return MPI_ARGV_NULL; }
