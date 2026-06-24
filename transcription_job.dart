/// Domain model for a transcription job.
/// Mirrors the backend's JobDetail schema.

enum JobStatus {
  pending,
  parsingPptx,
  transcribing,
  refining,
  done,
  failed;

  static JobStatus fromString(String s) {
    return switch (s) {
      'pending'       => pending,
      'parsing_pptx'  => parsingPptx,
      'transcribing'  => transcribing,
      'refining'      => refining,
      'done'          => done,
      'failed'        => failed,
      _               => pending,
    };
  }

  bool get isTerminal => this == done || this == failed;

  String get labelAr => switch (this) {
    pending       => 'في الانتظار',
    parsingPptx   => 'استخراج الشرائح',
    transcribing  => 'التفريغ الصوتي',
    refining      => 'التحرير الأكاديمي',
    done          => 'اكتمل',
    failed        => 'فشل',
  };
}

class TranscriptionJob {
  final String id;
  final JobStatus status;
  final String audioFilename;
  final String pptxFilename;
  final int progressPct;
  final String? errorMessage;
  final String? refinedTranscription;
  final String? rawTranscription;
  final double? audioDurationSec;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TranscriptionJob({
    required this.id,
    required this.status,
    required this.audioFilename,
    required this.pptxFilename,
    required this.progressPct,
    this.errorMessage,
    this.refinedTranscription,
    this.rawTranscription,
    this.audioDurationSec,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TranscriptionJob.fromJson(Map<String, dynamic> json) {
    return TranscriptionJob(
      id:                   json['id'] as String,
      status:               JobStatus.fromString(json['status'] as String),
      audioFilename:        json['audio_filename'] as String,
      pptxFilename:         json['pptx_filename'] as String,
      progressPct:          json['progress_pct'] as int,
      errorMessage:         json['error_message'] as String?,
      refinedTranscription: json['refined_transcription'] as String?,
      rawTranscription:     json['raw_transcription'] as String?,
      audioDurationSec:     (json['audio_duration_sec'] as num?)?.toDouble(),
      createdAt:            DateTime.parse(json['created_at'] as String),
      updatedAt:            DateTime.parse(json['updated_at'] as String),
    );
  }

  TranscriptionJob copyWith({
    JobStatus? status,
    int? progressPct,
    String? errorMessage,
    String? refinedTranscription,
  }) {
    return TranscriptionJob(
      id: id,
      status: status ?? this.status,
      audioFilename: audioFilename,
      pptxFilename: pptxFilename,
      progressPct: progressPct ?? this.progressPct,
      errorMessage: errorMessage ?? this.errorMessage,
      refinedTranscription: refinedTranscription ?? this.refinedTranscription,
      rawTranscription: rawTranscription,
      audioDurationSec: audioDurationSec,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
