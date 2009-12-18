estimateCommonDisp <- function(object,tol=1e-06) 
#	Do two iterations of calculating pseudodata and estimating common dispersion, first one uses Poisson
{
	if (!is(object,"DGEList"))
		stop("Currently supports DGEList objects")
	group<- object$samples$group <- as.factor(object$samples$group)
	levs.group<-levels(group)
	for(i in seq_len(2)) {
		if(i==1) disp <- 0 else disp <- common.dispersion$dispersion
		q2q.out<-equalizeLibSizes(object,disp=disp,null.hypothesis=FALSE)
		pseudo.obj<-new("DGEList",list(counts=q2q.out$pseudo, samples=object$samples))
		common.dispersion <- .estimateCommonDisp(pseudo.obj, tol=tol)
	}
	new("DGEList",list(samples=object$samples, common.dispersion=common.dispersion$dispersion, counts=object$counts, pseudo.alt=q2q.out$pseudo, genes=object$genes, conc=q2q.out$conc, common.lib.size=q2q.out$N))
}

.estimateCommonDisp <- function(object, tol=1e-06)
# Estimates the common dispersion (using conditional maximum likelihood)
# for fixed counts (y), assuming library sizes are equal
# Calculated on the delta = phi/(1+phi) scale,
# returns dispersion on the phi and the delta scale
# Now uses optimize instead of a grid search or Newton-Raphson
{
	nrows<-nrow(object$counts)
	levs.group<-levels(object$samples$group)
	y<-splitIntoGroups(object)
	delta <- optimize(commonCondLogLikDerDelta, interval=c(1e-4,100/(100+1)), tol=tol, maximum=TRUE, y=y, der=0, doSum=FALSE)
	delta <- delta$maximum
	list(dispersion=delta/(1-delta), dispersion.delta=delta)
}