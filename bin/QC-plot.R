library(stringr)
library(dplyr)
library(tibble)
library(ggplot2)
library(cowplot)

QC.file <- list.files(pattern = "-QC.txt", full.names = TRUE)
QC<-read.delim(QC.file,header = T,check.names = F)
Barcode.split<-str_split(QC$Barcode,"_",simplify=T)
QC$number<-Barcode.split[,ncol(Barcode.split)]
is_outlier <- function(x) {
  x < quantile(x, 0.25) - 1.5 * IQR(x) | x > quantile(x, 0.75) + 1.5 * IQR(x)
}

spike<-QC %>% mutate(is_outlier=ifelse(is_outlier(log10(`Spikein_reads`)), log10(`Spikein_reads`), as.numeric(NA)))
spike$number[which(is.na(spike$is_outlier))] <- as.numeric(NA)
spikein.plot<-ggplot(spike,aes(y=log10(`Spikein_reads`), x="")) + geom_boxplot(outlier.shape = NA) +geom_point(pch=21,color="darkgray", position = position_jitter(seed = 123))+ geom_text(color="red",fontface="bold",aes(label=number),na.rm=TRUE,position = position_jitter(seed = 123))+theme_bw(base_size = 16)+theme(plot.title = element_text(face = "bold", hjust=.5,size=24), axis.title=element_text(size = 18),axis.text.y=element_text(size = 14,color="black"),panel.grid.major.x = element_blank(),panel.grid.minor.x = element_blank(),panel.border = element_rect(colour = "black", fill=NA, size=1.2),axis.ticks.y = element_line(colour = "black"),axis.ticks.x = element_blank(),legend.title=element_blank())+ylab(expression(paste(log[10]~"(Spikein reads)")))+xlab("")+ggtitle("Spikein reads")

mapped<-QC %>% mutate(is_outlier=ifelse(is_outlier((`Mapped_reads`-`Spikein_reads`)/`Spikein_reads`), ((`Mapped_reads`-`Spikein_reads`)/`Spikein_reads`), as.numeric(NA)))
mapped$number[which(is.na(mapped$is_outlier))] <- as.numeric(NA)
mapped.plot<-ggplot(mapped,aes(y=((`Mapped_reads`-`Spikein_reads`)/`Spikein_reads`), x="")) + geom_boxplot(outlier.shape = NA) +geom_point(pch=21,color="darkgray", position = position_jitter(seed = 123))+ geom_text(color="red",fontface="bold",aes(label=number),na.rm=TRUE,position = position_jitter(seed = 123))+theme_bw(base_size = 16)+theme(plot.title = element_text(face = "bold", hjust=.5,size=24), axis.title=element_text(size = 18),axis.text.y=element_text(size = 14,color="black"),panel.grid.major.x = element_blank(),panel.grid.minor.x = element_blank(),panel.border = element_rect(colour = "black", fill=NA, size=1.2),axis.ticks.y = element_line(colour = "black"),axis.ticks.x = element_blank(),legend.title=element_blank())+ylab("(Mapped - Spikein) / Spikein")+xlab("")+ggtitle("Mapped / Spikein")

spike5<-QC %>% mutate(is_outlier=ifelse(is_outlier(`Spikein-5end_rate`), `Spikein-5end_rate`, as.numeric(NA)))
spike5$number[which(is.na(spike5$is_outlier))] <- as.numeric(NA)
spike5.plot<-ggplot(spike5,aes(y=(`Spikein-5end_rate`), x="")) + geom_boxplot(outlier.shape = NA) +geom_point(pch=21,color="darkgray", position = position_jitter(seed = 123))+ geom_text(color="red",fontface="bold",aes(label=number),na.rm=TRUE,position = position_jitter(seed = 123))+theme_bw(base_size = 16)+theme(plot.title = element_text(face = "bold", hjust=.5,size=24), axis.title=element_text(size = 18),axis.text.y=element_text(size = 14,color="black"),panel.grid.major.x = element_blank(),panel.grid.minor.x = element_blank(),panel.border = element_rect(colour = "black", fill=NA, size=1.2),axis.ticks.y = element_line(colour = "black"),axis.ticks.x = element_blank(),legend.title=element_blank())+ylab("Spikein 5'-end rate (%)")+xlab("")+ggtitle("Spikein 5'-end rate")

coding5<-QC %>% mutate(is_outlier=ifelse(is_outlier(`Coding-5end_rate`), `Coding-5end_rate`, as.numeric(NA)))
coding5$number[which(is.na(coding5$is_outlier))] <- as.numeric(NA)
coding5.plot<-ggplot(coding5,aes(y=(`Coding-5end_rate`), x="")) + geom_boxplot(outlier.shape = NA) +geom_point(pch=21,color="darkgray", position = position_jitter(seed = 123))+ geom_text(color="red",fontface="bold",aes(label=number),na.rm=TRUE,position = position_jitter(seed = 123))+theme_bw(base_size = 16)+theme(plot.title = element_text(face = "bold", hjust=.5,size=24), axis.title=element_text(size = 18),axis.text.y=element_text(size = 14,color="black"),panel.grid.major.x = element_blank(),panel.grid.minor.x = element_blank(),panel.border = element_rect(colour = "black", fill=NA, size=1.2),axis.ticks.y = element_line(colour = "black"),axis.ticks.x = element_blank(),legend.title=element_blank())+ylab("Coding 5'-end rate (%)")+xlab("")+ggtitle("Coding 5'-end rate")

pdf("QC-plots.pdf",paper="a4",width=0,height=0)
plot_grid(spikein.plot,mapped.plot,spike5.plot,coding5.plot, nrow = 2, align = "hv")
dev.off()
