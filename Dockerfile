# blastsimilarity includes NCBI tools, such as dust
FROM veupathdb/blastsimilarity:latest

# but it doesn't include seg, so get that manually
RUN wget ftp://ftp.ncbi.nih.gov/pub/seg/seg_src10.200301280.tar.gz && \
    tar -xzf seg_src10.200301280.tar.gz && \
    cd seg && \
    make

ENV PATH="/seg:${PATH}"

CMD ["seg"]