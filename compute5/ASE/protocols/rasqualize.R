args = commandArgs(trailingOnly=TRUE)

if (length(args)==0) {
  stop("At least one argument must be supplied (Y).txt", call.=FALSE)
}

################################################################GCCOR
Quantile <-
function(x,k=20){x=rank(x,ties="random"); z=rep(0,length(x));for(i in 1:k){z=z+as.numeric(x<=quantile(x,i/k,na.rm=T))};k-z}
gcCor <-
function(Y,gcvec,PLOT=F){
		#n=number of bins to use when performing GC correction. For exact method see section 6.1.1 in suppl. mat. of this paper: http://www.nature.com/nature/journal/v464/n7289/full/nature08872.html (Pickrell)
		n=200
		bin=Quantile(gcvec,n);
		x=sort(unlist(lapply(split(gcvec,bin),mean)))
		S=apply(Y,2,function(y){unlist(lapply(split(y,bin),sum))[as.character(0:(n-1))]});
    	Fs=log(t(t(S)/apply(S,2,sum))/apply(S,1,sum)*sum(as.numeric(S))); # Produces table of NA's until as.Numeric is given
    	is.na(Fs) <- sapply(Fs, is.infinite) #Replace all infinite values with NA
    	Fs[is.na(Fs)] <- 0 #Replace all NA's with 0
    
    	Gs=apply(Fs,2,function(y){smooth.spline(x,y,spar=1)$y});
    
        if(PLOT){
                par(mfcol=c(5,5),mar=c(2,2,2,2));
                for(i in 1:ncol(Y)){
                        plot(Fs[,i])
                        lines(Gs[,i],col=2)
                }
                matplot(x,Gs,type="l",col=2,lty=1)
        }
        exp(Gs[bin+1,])
}

#####################################################################

randomize <-
function(x,g=NULL){
        if(is.null(g)){
                n=ncol(x);
                t(apply(x,1,function(xx){xx[order(runif(n))]}))
        }else{
                for(i in unique(g)){
                        x[,g==i]=randomize(x[,g==i,drop=F])
                }
                x
        }
}


# MAKE BINARY RASQUAL
# read count and offset files (text)
textToBin <- function(fil,outfile){
		ytxt=fil
		# read tables
		y=read.table(ytxt,as.is=T)
		# output binary file names
		ybin=outfile
		# open files
		fybin=file(ybin,"wb")
		# write tables as binary
		writeBin(as.double(c(t(y[,-1]))), fybin)
		# close files
		close(fybin)
}


# Takes Y.txt and Gcc.txt and provides Ybin Kbin

# read count and gc content vector (text)
# input
ytxt=args[1]
# outfile K
ktxt=args[3]
gcc=args[2]
# read tables
Y=read.table(ytxt,as.is=T)
fid=Y[[1]]
Y=as.matrix(Y[,-1])
K=array(1, dim(Y))

# GC correction
if(!is.na(gcc)){
		gcc=scan(gcc)
		K=gcCor(Y,gcc)
}

# library size
sf=apply(Y,2,sum)
sf=sf/mean(sf)

# write K as binary
write.table(data.frame(fid, t(t(K)*sf)), col=F, row=F, sep="\t", file=ktxt, quote=F)
textToBin(ktxt, args[4])
textToBin(ytxt, args[5])

K=as.matrix(read.table(ktxt,as.is=T)[,-1])
n=ncol(Y)
xtxt=args[6]

# feature length
#len=scan(ltxt)

# fpm calculation
fpkm=t(t(Y/K+1)/apply(Y/K,2,sum))*1e6 #  /len*1e9

# Singular value decomposition
fpkm.svd   = svd((log(fpkm)-apply(log(fpkm),1,mean))/apply(log(fpkm),1,sd))
fpkm.svd.r = svd(randomize((log(fpkm)-apply(log(fpkm),1,mean))/apply(log(fpkm),1,sd)))

# Covariate selection
sf=log(apply(Y,2,sum))

covs=fpkm.svd$v[,1:sum(fpkm.svd$d[-n]>fpkm.svd.r$d[-n])]

if (is.vector(covs)){
		if(cor(sf,covs)^2<0.9){covs=cbind(sf, covs)}
	}else{
		if(cor(sf,covs[,1])^2<0.9){covs=cbind(sf, covs)}
}

# Write covariates
write.table(covs,col=F,row=F,sep="\t",quote=F,file=xtxt)
