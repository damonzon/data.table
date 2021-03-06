\name{:=}
\alias{:=}
\alias{set}
\title{ Assignment by reference }
\description{
    Fast add, remove and modify subsets of columns, by reference.
}
\usage{
#   DT[i, LHS:=RHS, by=...]

#   DT[i, c("LHS1","LHS2") := list(RHS1, RHS2), by=...]

#   DT[i, `:=`(LHS1=RHS1,
#              LHS2=RHS2,
#              ...), by=...]
    
    set(x, i=NULL, j, value)
}
\arguments{
\item{LHS}{ A single column name. Or, when \code{with=FALSE}, a vector of column names or numeric positions (or a variable that evaluates as such). If the column doesn't exist, it is added, by reference. }
\item{RHS}{ A vector of replacement values. It is recycled in the usual way to fill the number of rows satisfying \code{i}, if any. Or, when \code{with=FALSE}, a \code{list} of replacement vectors which are applied (the \code{list} is recycled if necessary) to each column of \code{LHS} . To remove a column use \code{NULL}. }
\item{x}{ A \code{data.table}. Or, \code{set()} accepts \code{data.frame}, too. }
\item{i}{ Optional. In set(), integer row numbers to be assigned \code{value}. \code{NULL} represents all rows more efficiently than creating a vector such as \code{1:nrow(x)}. }
\item{j}{ In set(), integer column number to be assigned \code{value}. }
\item{value}{ Value to assign by reference to \code{x[i,j]}. }
}
\details{
\code{:=} is defined for use in \code{j} only. It \emph{updates} or \emph{adds} the column(s) by reference. It makes no copies of any part of memory at all. Typical usages are :
\preformatted{
    DT[i,colname:=value]                      # update (or add at the end if doesn't exist) a column called "colname" with value where i and (when new column) NA elsewhere
    DT[i,"colname \%":=value]                  # same. column called "colname \%"
    DT[i,(3:6):=value]                        # update existing columns 3:6 with value. Aside: parens are not required here since : already makes LHS a call rather than a symbol
    DT[i,colnamevector:=value,with=FALSE]     # old syntax. The contents of colnamevector in calling scope determine the column names or positions to update (or add)
    DT[i,(colnamevector):=value]              # same, shorthand. Now preferred. The parens are enough to stop the LHS being a symbol
    DT[i,colC:=mean(colB),by=colA]            # update (or add) column called "colC" by reference by group. A major feature of `:=`.
    DT[,`:=`(new1=sum(colB), new2=sum(colC))] # multiple :=.  
}
The following all result in a friendly error (by design) :
\preformatted{
    x := 1L                                   # friendly error
    DT[i,colname] := value                    # friendly error
    DT[i]$colname := value                    # friendly error
    DT[,{col1:=1L;col2:=2L}]                  # friendly error. Use `:=`() instead for multiple := (see above)
}

\code{:=} in \code{j} can be combined with all types of \code{i} (such as binary search), and all types of \code{by}. This a one reason why \code{:=} has been implemented in \code{j}. See FAQ 2.16 for analogies to SQL. \cr\cr  % for some reason in this .Rd file (but not the others), newlines seem to be ignored.

When \code{LHS} is a factor column and \code{RHS} is a character vector with items missing from the factor levels, the new level(s) are automatically added (by reference, efficiently), unlike base methods.\cr\cr

Unlike \code{<-} for \code{data.frame}, the (potentially large) LHS is not coerced to match the type of the (often small) RHS. Instead the RHS is coerced to match the type of the LHS, if necessary. Where this involves double precision values being coerced to an integer column, a warning is given (whether or not fractional data is truncated). The motivation for this is efficiency. It is best to get the column types correct up front and stick to them. Changing a column type is possible but deliberately harder: provide a whole column as the RHS. This RHS is then \emph{plonked} into that column slot and we call this \emph{plonk syntax}, or \emph{replace column syntax} if you prefer. By needing to construct a full length vector of a new type, you as the user are more aware of what is happening, and it's clearer to readers of your code that you really do intend to change the column type.\cr\cr

\code{data.table}s are \emph{not} copied-on-change by \code{:=}, \code{setkey} or any of the other \code{set*} functions. See \code{\link{copy}}.\cr\cr

Additional resources: search for "\code{:=}" in the \href{../doc/datatable-faq.pdf}{FAQs vignette} (3 FAQs mention \code{:=}), search Stack Overflow's \href{http://stackoverflow.com/search?q=\%5Bdata.table\%5D+reference}{data.table tag for "reference"} (6 questions).\cr\cr

Advanced (internals) : sub assigning to existing columns is easy to see how that is done internally. Removing columns by reference is also straightforward by modifying the vector of column pointers only (using memmove in C). Adding columns is more tricky to see how that can be grown by reference: the list vector of column pointers is over-allocated, see \code{\link{truelength}}. By defining \code{:=} in \code{j} we believe update synax is natural, and scales, but also it bypasses \code{[<-} dispatch via \code{*tmp*} and allows \code{:=} to update by reference with no copies of any part of memory at all.\cr\cr

Since \code{[.data.table} incurs overhead to check the existence and type of arguments (for example), \code{set()} provides direct (but less flexible) assignment by reference with low overhead, appropriate for use inside a \code{for} loop. See examples. \code{:=} is more flexible than \code{set()} because \code{:=} is intended to be combined with \code{i} and \code{by} in single queries on large datasets.

}
\value{
    \code{DT} is modified by reference and the new value is returned. If you require a copy, take a copy first (using \code{DT2=copy(DT)}). Recall that this package is for large data (of mixed column types, with multi-column keys) where updates by reference can be many orders of magnitude faster than copying the entire table.   
}
\seealso{ \code{\link{data.table}}, \code{\link{copy}}, \code{\link{alloc.col}}, \code{\link{truelength}}, \code{\link{set}}
}
\examples{
DT = data.table(a=LETTERS[c(1,1:3)],b=4:7,key="a")
DT[,c:=8]        # add a numeric column, 8 for all rows
DT[,d:=9L]       # add an integer column, 9L for all rows
DT[,c:=NULL]     # remove column c
DT[2,d:=10L]     # subassign by reference to column d
DT               # DT changed by reference

DT[b>4,b:=d*2L]  # subassign to b using d, where b>4
DT["A",b:=0L]    # binary search for group "A" and set column b

DT[,e:=mean(d),by=a]  # add new column by group by reference
DT["B",f:=mean(d)]    # subassign to new column, NA initialized

\dontrun{
# Speed example ...
    
m = matrix(1,nrow=100000,ncol=100)
DF = as.data.frame(m)
DT = as.data.table(m)    

system.time(for (i in 1:1000) DF[i,1] <- i)
# 591 seconds      
system.time(for (i in 1:1000) DT[i,V1:=i])
# 2.4 seconds  ( 246 times faster, 2.4 is overhead in [.data.table )
system.time(for (i in 1:1000) set(DT,i,1L,i))
# 0.03 seconds  ( 19700 times faster, overhead of [.data.table is avoided )

# However, normally, we call [.data.table *once* on *large* data, not many times on small data.
# The above is to demonstrate overhead, not to recommend looping in this way. But the option
# of set() is there if you need it.
}
    
}
\keyword{ data }


