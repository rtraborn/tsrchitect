#' @title \strong{writeTSS}
#'
#' @description \code{writeTSS} writes identified TSSs
#' from a specified data set to a file in either tab or BED formats
#'
#' @param experimentName an S4 object of class \emph{tssObject} containing
#' information in slot \emph{@@tssCountData}
#' @param tssSetType specifies the set to be written to file.
#' Options are "replicates" or "merged". (character)
#' @param tssSet number of the dataset to be processed (numeric).
#' @param tssLabel specifies the label to be used in the name column of
#' BED format output
#' @param mixedorder a logical specifying whether the sequence names should
#' be ordered alphanumerically ("10" following "9" rather than "1"). (logical)
#' @param fileType the format of the file to be written.
#' Possible choices are "tab" for tab-delimited output, "bed" for BED format,
#' and "bedGraph" for BedGraph format (character). In case "bedGraph," three
#' output files are produced: *_PLUS.bedGraph and *_MINUS.bedGraph, which
#' record the number of TSS tags per position on plus and minus strand
#' separately; and a combined *.bedGraph file which lists plus strand tag
#' counts as positive numbers, minus strand tag counts as negative numbers,
#' and positions with both plus and minus strand tag counts display the
#' tag count corresponding to the highest absolute value.
#'
#' @return A table containing the specified TSS data set that
#' is to be written to your working directory.
#'
#' @import     BiocGenerics
#' @importFrom gtools mixedorder
#' @importFrom rtracklayer export.bed
#'
#' @examples
#' load(system.file("extdata", "tssObjectExample.RData", package="TSRchitect"))
#' writeTSS(experimentName=tssObjectExample, tssSetType="replicates",
#'          tssSet=1, tssLabel="TSSsample1_", mixedorder=FALSE, fileType="tab")
#'
#' @note The .bed file written adheres to the standard six-column BED format,
#' while "tab" format is identical to that of the data.frames containing TSS
#' data.
#' @note For more information on the BED format, please visit
#' https://genome.ucsc.edu/FAQ/FAQformat#format1
#'
#' @export
#' @rdname writeTSS-methods


setGeneric("writeTSS",
    function(experimentName, tssSetType, tssSet=1, tssLabel="TSS_",
             mixedorder=FALSE, fileType="tab")
    standardGeneric("writeTSS")
)

#' @rdname writeTSS-methods

setMethod("writeTSS",
          signature(experimentName="tssObject", "character", "numeric",
		    "character", "logical", "character"),

          function(experimentName, tssSetType, tssSet,
                   tssLabel, mixedorder, fileType) {

              message("... writeTSS ...")
              if (tssSetType=="replicates") {
                  if (tssSet>length(experimentName@tssCountData)) {
                      stop("The value selected for tssSet exceeds the",
                           " number of slots in tssCountData.")
                  }
                  outfname <- paste("TSSset-", tssSet, sep="")
                  if (fileType == "tab") {
                      outfname <- paste(outfname, "tab", sep=".")
                  } else if (fileType == "bed") {
                      outfname <- paste(outfname, "bed", sep=".")
                  } else if (fileType == "bedGraph") {
                      outfname <- paste(outfname, "bedGraph", sep=".")
                  } else {
                      stop("Unknown fileType selected for writeTSS.",
                           " Please check.")
                  }
                  message("\nThe TSS set for TSS dataset ", tssSet,
                          " will be written to file ",
                          outfname, "\nin your working directory.")

                  if (!missing(mixedorder) & mixedorder == TRUE) {
                    tss.df <- experimentName@tssCountData[[tssSet]][mixedorder(
                                   experimentName@tssCountData[[tssSet]]$seq),]

		  } else {
                    tss.df <- experimentName@tssCountData[[tssSet]]
		  }

              } else if (tssSetType=="merged") {
                  if (length(experimentName@tssCountDataMerged)<1) {
                      stop("The @tssCountDataMerged slot is currently empty.",
                           " Please complete the merger before continuing.")
                  }
                  if (tssSet>length(experimentName@tssCountDataMerged)) {
                      stop("The value selected for tssSet exceeds the",
                           " number of slots in tssCountDataMerged.")
                  }
                  if (tssSet<length(experimentName@tssCountDataMerged)) {
                      outfname <- paste("TSSsetMerged-", tssSet, sep="")
                      if (fileType == "tab") {
                          outfname <- paste(outfname, "tab", sep=".")
                      } else if (fileType == "bed") {
                          outfname <- paste(outfname, "bed", sep=".")
                      } else if (fileType == "bedGraph") {
                          outfname <- paste(outfname, "bedGraph", sep=".")
                      } else {
                          stop("Unknown fileType selected for writeTSS.",
                               " Please check.")
                      }
                      message("\nThe merged TSS set for TSS dataset ", tssSet,
                      " will be written to file ", outfname,
                      "\nin your working directory.")
                  } else { # "combined" case
                      if (fileType == "tab") {
                          outfname <- "TSSsetCombined.tab"
                      } else if (fileType == "bed") {
                          outfname <- "TSSsetCombined.bed"
                      } else if (fileType == "bedGraph") {
                          outfname <- "TSSsetCombined.bedGraph"
                      } else {
                          stop("Unknown fileType selected for writeTSS.",
                               " Please check.")
                      }
                      message("\nThe combined TSS set derived from all samples",
                              " will be written to file ", outfname,
                              "\nin your working directory.")
                  }
                  if (!missing(mixedorder) & mixedorder == TRUE) {
                    tss.df <- experimentName@tssCountDataMerged[[tssSet]][mixedorder(
                                   experimentName@tssCountDataMerged[[tssSet]]$seq),]
		  } else {
                    tss.df <- experimentName@tssCountDataMerged[[tssSet]]
		  }
              } else {
                  stop("Error: argument tssSetType to writeTSS() should be",
                       " either \"replicates\" or \"merged\".")
              }

              if (fileType == "tab") {
                  write.table(format(tss.df,scientific=FALSE), file=outfname,
                              col.names=FALSE, row.names=FALSE, sep="\t",
                              quote=FALSE)
              } else if (fileType == "bed") {
                  tss.df$ID <- paste(tssLabel,which(tss.df$seq != ""),sep="_")
                  out.df <- tss.df[, c("seq", "TSS", "TSS", "ID",
                                       "nTAGs", "strand")]
                  colnames(out.df) <- c("chrom", "start", "end", "name",
                                        "score", "strand")
                  export.bed(out.df,con=outfname)
              } else { # fileType == "bedGraph") 
                  tss.df$beg <- tss.df$TSS -1;
                  tssP.df <- tss.df[tss.df$strand=="+",
				    c("seq", "beg", "TSS", "nTAGs")]
                  write.table(format(tssP.df,scientific=FALSE,trim=TRUE),
                              file=sub(".bedGraph","_PLUS.bedGraph",outfname),
			      col.names=FALSE, row.names=FALSE,
                              sep="\t", quote=FALSE)
                  tssM.df <- tss.df[tss.df$strand=="-",
				    c("seq", "beg", "TSS", "nTAGs")]
                  write.table(format(tssM.df,scientific=FALSE,trim=TRUE),
                              file=sub(".bedGraph","_MINUS.bedGraph",outfname),
			      col.names=FALSE, row.names=FALSE,
                              sep="\t", quote=FALSE)


                  tss.df$score[tss.df$strand=="+"] <-
                                                tss.df$nTAGs[tss.df$strand=="+"]
                  tss.df$score[tss.df$strand=="-"] <-
                                               -tss.df$nTAGs[tss.df$strand=="-"]

		  # ... bigWig (a common way to display bedGraph files) does not
		  # tolerate overlapping regions, thus we record only the
		  # maximal tag count in a position that is recorded both on the
		  # plus and the minus strand (presumably a rare event ...):

		  tmptssdf <- tss.df[,c("seq","beg")]
                  i1 <- row.names(tmptssdf[duplicated(tmptssdf),])
                  i2 <- row.names(tmptssdf[duplicated(tmptssdf,fromLast=TRUE),])
                  j1 <- ifelse (abs(tss.df[i1,"score"])
                                                < abs(tss.df[i2,"score"]),i1,i2)
                  j2 <- ifelse (abs(tss.df[i1,"score"])
                                               >= abs(tss.df[i2,"score"]),i1,i2)
                  tss.df[j1,] <- tss.df[j2,]
                  tss.df <- tss.df[!duplicated(tss.df),]

                  out.df <- tss.df[with(tss.df,order(tss.df$seq,tss.df$beg)),
                                   c("seq", "beg", "TSS", "score")]
                  write.table(format(out.df,scientific=FALSE,trim=TRUE),
                              file=outfname, col.names=FALSE, row.names=FALSE,
                              sep="\t", quote=FALSE)
              }

              message("---------------------------------------------------------\n")
              message(" Done.\n")
          }
          )
