# Workflow combining tasks together
workflow finemapping {
  File inputManifestFile
  Array[Array[String]] inputManifest = read_tsv(inputManifestFile)
  scatter (study in inputManifest) {
    call finemap_single_study {
      input:
        pq=study[0],
        ld=study[1],
        study_id=study[2],
        cell_id=study[3],
        group_id=study[4],
        trait_id=study[5],
        chrom=study[6],
        method=study[7],
        toploci=study[8],
        credset=study[9],
        log=study[10],
        tmpdir=study[11]
    }
  }
  call concat_parquets as concat_toploci {
    input:
      in=finemap_single_study.toploci_res
  }
  call concat_parquets as concat_credset {
    input:
      in=finemap_single_study.credset_res
  }
}

# Task to run the finemapping script
task finemap_single_study {
  String script
  String pq
  String ld
  File config_file
  String study_id
  String? cell_id
  String? group_id
  String trait_id
  String chrom
  String method
  String toploci
  String credset
  String log
  String tmpdir
  command {
    python ${script} \
      --pq ${pq} \
      --ld ${ld} \
      --config_file ${config_file} \
      --study_id ${study_id} \
      --trait_id ${trait_id} \
      --chrom ${chrom} \
      --cell_id ${default='""' cell_id} \
      --group_id ${default='""' group_id} \
      --method ${method} \
      --toploci ${toploci} \
      --credset ${credset} \
      --log ${log} \
      --tmpdir ${tmpdir}
  }
  output {
    File toploci_res = "${toploci}"
    File credset_res = "${credset}"
  }
}

# Task to load parquets into memory and write to a single file
task concat_parquets {
  String script
  Array[File] in
  String out
  command {
    python ${script} \
      --in_parquets ${sep=" " in} \
      --out ${out} \
  }
  output {
    File result = "${out}"
  }
}