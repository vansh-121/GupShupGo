// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $MessagePlaintextsTable extends MessagePlaintexts
    with TableInfo<$MessagePlaintextsTable, MessagePlaintext> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessagePlaintextsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _savedAtMeta =
      const VerificationMeta('savedAt');
  @override
  late final GeneratedColumn<int> savedAt = GeneratedColumn<int>(
      'saved_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, payload, savedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'message_plaintext';
  @override
  VerificationContext validateIntegrity(Insertable<MessagePlaintext> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('saved_at')) {
      context.handle(_savedAtMeta,
          savedAt.isAcceptableOrUnknown(data['saved_at']!, _savedAtMeta));
    } else if (isInserting) {
      context.missing(_savedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MessagePlaintext map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MessagePlaintext(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload'])!,
      savedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}saved_at'])!,
    );
  }

  @override
  $MessagePlaintextsTable createAlias(String alias) {
    return $MessagePlaintextsTable(attachedDatabase, alias);
  }
}

class MessagePlaintext extends DataClass
    implements Insertable<MessagePlaintext> {
  final String id;
  final String payload;
  final int savedAt;
  const MessagePlaintext(
      {required this.id, required this.payload, required this.savedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['payload'] = Variable<String>(payload);
    map['saved_at'] = Variable<int>(savedAt);
    return map;
  }

  MessagePlaintextsCompanion toCompanion(bool nullToAbsent) {
    return MessagePlaintextsCompanion(
      id: Value(id),
      payload: Value(payload),
      savedAt: Value(savedAt),
    );
  }

  factory MessagePlaintext.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MessagePlaintext(
      id: serializer.fromJson<String>(json['id']),
      payload: serializer.fromJson<String>(json['payload']),
      savedAt: serializer.fromJson<int>(json['savedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'payload': serializer.toJson<String>(payload),
      'savedAt': serializer.toJson<int>(savedAt),
    };
  }

  MessagePlaintext copyWith({String? id, String? payload, int? savedAt}) =>
      MessagePlaintext(
        id: id ?? this.id,
        payload: payload ?? this.payload,
        savedAt: savedAt ?? this.savedAt,
      );
  MessagePlaintext copyWithCompanion(MessagePlaintextsCompanion data) {
    return MessagePlaintext(
      id: data.id.present ? data.id.value : this.id,
      payload: data.payload.present ? data.payload.value : this.payload,
      savedAt: data.savedAt.present ? data.savedAt.value : this.savedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MessagePlaintext(')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('savedAt: $savedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, payload, savedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MessagePlaintext &&
          other.id == this.id &&
          other.payload == this.payload &&
          other.savedAt == this.savedAt);
}

class MessagePlaintextsCompanion extends UpdateCompanion<MessagePlaintext> {
  final Value<String> id;
  final Value<String> payload;
  final Value<int> savedAt;
  final Value<int> rowid;
  const MessagePlaintextsCompanion({
    this.id = const Value.absent(),
    this.payload = const Value.absent(),
    this.savedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MessagePlaintextsCompanion.insert({
    required String id,
    required String payload,
    required int savedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        payload = Value(payload),
        savedAt = Value(savedAt);
  static Insertable<MessagePlaintext> custom({
    Expression<String>? id,
    Expression<String>? payload,
    Expression<int>? savedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (payload != null) 'payload': payload,
      if (savedAt != null) 'saved_at': savedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MessagePlaintextsCompanion copyWith(
      {Value<String>? id,
      Value<String>? payload,
      Value<int>? savedAt,
      Value<int>? rowid}) {
    return MessagePlaintextsCompanion(
      id: id ?? this.id,
      payload: payload ?? this.payload,
      savedAt: savedAt ?? this.savedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (savedAt.present) {
      map['saved_at'] = Variable<int>(savedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagePlaintextsCompanion(')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('savedAt: $savedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChatRoomPreviewsTable extends ChatRoomPreviews
    with TableInfo<$ChatRoomPreviewsTable, ChatRoomPreview> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatRoomPreviewsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _chatRoomIdMeta =
      const VerificationMeta('chatRoomId');
  @override
  late final GeneratedColumn<String> chatRoomId = GeneratedColumn<String>(
      'chat_room_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lastMessageTextMeta =
      const VerificationMeta('lastMessageText');
  @override
  late final GeneratedColumn<String> lastMessageText = GeneratedColumn<String>(
      'last_message_text', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lastMessageIdMeta =
      const VerificationMeta('lastMessageId');
  @override
  late final GeneratedColumn<String> lastMessageId = GeneratedColumn<String>(
      'last_message_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [chatRoomId, lastMessageText, lastMessageId, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chat_room_preview';
  @override
  VerificationContext validateIntegrity(Insertable<ChatRoomPreview> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('chat_room_id')) {
      context.handle(
          _chatRoomIdMeta,
          chatRoomId.isAcceptableOrUnknown(
              data['chat_room_id']!, _chatRoomIdMeta));
    } else if (isInserting) {
      context.missing(_chatRoomIdMeta);
    }
    if (data.containsKey('last_message_text')) {
      context.handle(
          _lastMessageTextMeta,
          lastMessageText.isAcceptableOrUnknown(
              data['last_message_text']!, _lastMessageTextMeta));
    } else if (isInserting) {
      context.missing(_lastMessageTextMeta);
    }
    if (data.containsKey('last_message_id')) {
      context.handle(
          _lastMessageIdMeta,
          lastMessageId.isAcceptableOrUnknown(
              data['last_message_id']!, _lastMessageIdMeta));
    } else if (isInserting) {
      context.missing(_lastMessageIdMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {chatRoomId};
  @override
  ChatRoomPreview map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChatRoomPreview(
      chatRoomId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}chat_room_id'])!,
      lastMessageText: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}last_message_text'])!,
      lastMessageId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}last_message_id'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ChatRoomPreviewsTable createAlias(String alias) {
    return $ChatRoomPreviewsTable(attachedDatabase, alias);
  }
}

class ChatRoomPreview extends DataClass implements Insertable<ChatRoomPreview> {
  final String chatRoomId;
  final String lastMessageText;
  final String lastMessageId;
  final int updatedAt;
  const ChatRoomPreview(
      {required this.chatRoomId,
      required this.lastMessageText,
      required this.lastMessageId,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['chat_room_id'] = Variable<String>(chatRoomId);
    map['last_message_text'] = Variable<String>(lastMessageText);
    map['last_message_id'] = Variable<String>(lastMessageId);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  ChatRoomPreviewsCompanion toCompanion(bool nullToAbsent) {
    return ChatRoomPreviewsCompanion(
      chatRoomId: Value(chatRoomId),
      lastMessageText: Value(lastMessageText),
      lastMessageId: Value(lastMessageId),
      updatedAt: Value(updatedAt),
    );
  }

  factory ChatRoomPreview.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChatRoomPreview(
      chatRoomId: serializer.fromJson<String>(json['chatRoomId']),
      lastMessageText: serializer.fromJson<String>(json['lastMessageText']),
      lastMessageId: serializer.fromJson<String>(json['lastMessageId']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'chatRoomId': serializer.toJson<String>(chatRoomId),
      'lastMessageText': serializer.toJson<String>(lastMessageText),
      'lastMessageId': serializer.toJson<String>(lastMessageId),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  ChatRoomPreview copyWith(
          {String? chatRoomId,
          String? lastMessageText,
          String? lastMessageId,
          int? updatedAt}) =>
      ChatRoomPreview(
        chatRoomId: chatRoomId ?? this.chatRoomId,
        lastMessageText: lastMessageText ?? this.lastMessageText,
        lastMessageId: lastMessageId ?? this.lastMessageId,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  ChatRoomPreview copyWithCompanion(ChatRoomPreviewsCompanion data) {
    return ChatRoomPreview(
      chatRoomId:
          data.chatRoomId.present ? data.chatRoomId.value : this.chatRoomId,
      lastMessageText: data.lastMessageText.present
          ? data.lastMessageText.value
          : this.lastMessageText,
      lastMessageId: data.lastMessageId.present
          ? data.lastMessageId.value
          : this.lastMessageId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChatRoomPreview(')
          ..write('chatRoomId: $chatRoomId, ')
          ..write('lastMessageText: $lastMessageText, ')
          ..write('lastMessageId: $lastMessageId, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(chatRoomId, lastMessageText, lastMessageId, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatRoomPreview &&
          other.chatRoomId == this.chatRoomId &&
          other.lastMessageText == this.lastMessageText &&
          other.lastMessageId == this.lastMessageId &&
          other.updatedAt == this.updatedAt);
}

class ChatRoomPreviewsCompanion extends UpdateCompanion<ChatRoomPreview> {
  final Value<String> chatRoomId;
  final Value<String> lastMessageText;
  final Value<String> lastMessageId;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const ChatRoomPreviewsCompanion({
    this.chatRoomId = const Value.absent(),
    this.lastMessageText = const Value.absent(),
    this.lastMessageId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChatRoomPreviewsCompanion.insert({
    required String chatRoomId,
    required String lastMessageText,
    required String lastMessageId,
    required int updatedAt,
    this.rowid = const Value.absent(),
  })  : chatRoomId = Value(chatRoomId),
        lastMessageText = Value(lastMessageText),
        lastMessageId = Value(lastMessageId),
        updatedAt = Value(updatedAt);
  static Insertable<ChatRoomPreview> custom({
    Expression<String>? chatRoomId,
    Expression<String>? lastMessageText,
    Expression<String>? lastMessageId,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (chatRoomId != null) 'chat_room_id': chatRoomId,
      if (lastMessageText != null) 'last_message_text': lastMessageText,
      if (lastMessageId != null) 'last_message_id': lastMessageId,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChatRoomPreviewsCompanion copyWith(
      {Value<String>? chatRoomId,
      Value<String>? lastMessageText,
      Value<String>? lastMessageId,
      Value<int>? updatedAt,
      Value<int>? rowid}) {
    return ChatRoomPreviewsCompanion(
      chatRoomId: chatRoomId ?? this.chatRoomId,
      lastMessageText: lastMessageText ?? this.lastMessageText,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (chatRoomId.present) {
      map['chat_room_id'] = Variable<String>(chatRoomId.value);
    }
    if (lastMessageText.present) {
      map['last_message_text'] = Variable<String>(lastMessageText.value);
    }
    if (lastMessageId.present) {
      map['last_message_id'] = Variable<String>(lastMessageId.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatRoomPreviewsCompanion(')
          ..write('chatRoomId: $chatRoomId, ')
          ..write('lastMessageText: $lastMessageText, ')
          ..write('lastMessageId: $lastMessageId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalMessagesTable extends LocalMessages
    with TableInfo<$LocalMessagesTable, LocalMessage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _chatRoomIdMeta =
      const VerificationMeta('chatRoomId');
  @override
  late final GeneratedColumn<String> chatRoomId = GeneratedColumn<String>(
      'chat_room_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _messageJsonMeta =
      const VerificationMeta('messageJson');
  @override
  late final GeneratedColumn<String> messageJson = GeneratedColumn<String>(
      'message_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<int> timestamp = GeneratedColumn<int>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, chatRoomId, messageJson, timestamp];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_messages';
  @override
  VerificationContext validateIntegrity(Insertable<LocalMessage> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('chat_room_id')) {
      context.handle(
          _chatRoomIdMeta,
          chatRoomId.isAcceptableOrUnknown(
              data['chat_room_id']!, _chatRoomIdMeta));
    } else if (isInserting) {
      context.missing(_chatRoomIdMeta);
    }
    if (data.containsKey('message_json')) {
      context.handle(
          _messageJsonMeta,
          messageJson.isAcceptableOrUnknown(
              data['message_json']!, _messageJsonMeta));
    } else if (isInserting) {
      context.missing(_messageJsonMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalMessage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalMessage(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      chatRoomId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}chat_room_id'])!,
      messageJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message_json'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}timestamp'])!,
    );
  }

  @override
  $LocalMessagesTable createAlias(String alias) {
    return $LocalMessagesTable(attachedDatabase, alias);
  }
}

class LocalMessage extends DataClass implements Insertable<LocalMessage> {
  final String id;
  final String chatRoomId;
  final String messageJson;
  final int timestamp;
  const LocalMessage(
      {required this.id,
      required this.chatRoomId,
      required this.messageJson,
      required this.timestamp});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['chat_room_id'] = Variable<String>(chatRoomId);
    map['message_json'] = Variable<String>(messageJson);
    map['timestamp'] = Variable<int>(timestamp);
    return map;
  }

  LocalMessagesCompanion toCompanion(bool nullToAbsent) {
    return LocalMessagesCompanion(
      id: Value(id),
      chatRoomId: Value(chatRoomId),
      messageJson: Value(messageJson),
      timestamp: Value(timestamp),
    );
  }

  factory LocalMessage.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalMessage(
      id: serializer.fromJson<String>(json['id']),
      chatRoomId: serializer.fromJson<String>(json['chatRoomId']),
      messageJson: serializer.fromJson<String>(json['messageJson']),
      timestamp: serializer.fromJson<int>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'chatRoomId': serializer.toJson<String>(chatRoomId),
      'messageJson': serializer.toJson<String>(messageJson),
      'timestamp': serializer.toJson<int>(timestamp),
    };
  }

  LocalMessage copyWith(
          {String? id,
          String? chatRoomId,
          String? messageJson,
          int? timestamp}) =>
      LocalMessage(
        id: id ?? this.id,
        chatRoomId: chatRoomId ?? this.chatRoomId,
        messageJson: messageJson ?? this.messageJson,
        timestamp: timestamp ?? this.timestamp,
      );
  LocalMessage copyWithCompanion(LocalMessagesCompanion data) {
    return LocalMessage(
      id: data.id.present ? data.id.value : this.id,
      chatRoomId:
          data.chatRoomId.present ? data.chatRoomId.value : this.chatRoomId,
      messageJson:
          data.messageJson.present ? data.messageJson.value : this.messageJson,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalMessage(')
          ..write('id: $id, ')
          ..write('chatRoomId: $chatRoomId, ')
          ..write('messageJson: $messageJson, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, chatRoomId, messageJson, timestamp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalMessage &&
          other.id == this.id &&
          other.chatRoomId == this.chatRoomId &&
          other.messageJson == this.messageJson &&
          other.timestamp == this.timestamp);
}

class LocalMessagesCompanion extends UpdateCompanion<LocalMessage> {
  final Value<String> id;
  final Value<String> chatRoomId;
  final Value<String> messageJson;
  final Value<int> timestamp;
  final Value<int> rowid;
  const LocalMessagesCompanion({
    this.id = const Value.absent(),
    this.chatRoomId = const Value.absent(),
    this.messageJson = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalMessagesCompanion.insert({
    required String id,
    required String chatRoomId,
    required String messageJson,
    required int timestamp,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        chatRoomId = Value(chatRoomId),
        messageJson = Value(messageJson),
        timestamp = Value(timestamp);
  static Insertable<LocalMessage> custom({
    Expression<String>? id,
    Expression<String>? chatRoomId,
    Expression<String>? messageJson,
    Expression<int>? timestamp,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (chatRoomId != null) 'chat_room_id': chatRoomId,
      if (messageJson != null) 'message_json': messageJson,
      if (timestamp != null) 'timestamp': timestamp,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalMessagesCompanion copyWith(
      {Value<String>? id,
      Value<String>? chatRoomId,
      Value<String>? messageJson,
      Value<int>? timestamp,
      Value<int>? rowid}) {
    return LocalMessagesCompanion(
      id: id ?? this.id,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      messageJson: messageJson ?? this.messageJson,
      timestamp: timestamp ?? this.timestamp,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (chatRoomId.present) {
      map['chat_room_id'] = Variable<String>(chatRoomId.value);
    }
    if (messageJson.present) {
      map['message_json'] = Variable<String>(messageJson.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<int>(timestamp.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalMessagesCompanion(')
          ..write('id: $id, ')
          ..write('chatRoomId: $chatRoomId, ')
          ..write('messageJson: $messageJson, ')
          ..write('timestamp: $timestamp, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MessagePlaintextsTable messagePlaintexts =
      $MessagePlaintextsTable(this);
  late final $ChatRoomPreviewsTable chatRoomPreviews =
      $ChatRoomPreviewsTable(this);
  late final $LocalMessagesTable localMessages = $LocalMessagesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [messagePlaintexts, chatRoomPreviews, localMessages];
}

typedef $$MessagePlaintextsTableCreateCompanionBuilder
    = MessagePlaintextsCompanion Function({
  required String id,
  required String payload,
  required int savedAt,
  Value<int> rowid,
});
typedef $$MessagePlaintextsTableUpdateCompanionBuilder
    = MessagePlaintextsCompanion Function({
  Value<String> id,
  Value<String> payload,
  Value<int> savedAt,
  Value<int> rowid,
});

class $$MessagePlaintextsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MessagePlaintextsTable,
    MessagePlaintext,
    $$MessagePlaintextsTableFilterComposer,
    $$MessagePlaintextsTableOrderingComposer,
    $$MessagePlaintextsTableCreateCompanionBuilder,
    $$MessagePlaintextsTableUpdateCompanionBuilder> {
  $$MessagePlaintextsTableTableManager(
      _$AppDatabase db, $MessagePlaintextsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$MessagePlaintextsTableFilterComposer(ComposerState(db, table)),
          orderingComposer: $$MessagePlaintextsTableOrderingComposer(
              ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<int> savedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MessagePlaintextsCompanion(
            id: id,
            payload: payload,
            savedAt: savedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String payload,
            required int savedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              MessagePlaintextsCompanion.insert(
            id: id,
            payload: payload,
            savedAt: savedAt,
            rowid: rowid,
          ),
        ));
}

class $$MessagePlaintextsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $MessagePlaintextsTable> {
  $$MessagePlaintextsTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get payload => $state.composableBuilder(
      column: $state.table.payload,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get savedAt => $state.composableBuilder(
      column: $state.table.savedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$MessagePlaintextsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $MessagePlaintextsTable> {
  $$MessagePlaintextsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get payload => $state.composableBuilder(
      column: $state.table.payload,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get savedAt => $state.composableBuilder(
      column: $state.table.savedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$ChatRoomPreviewsTableCreateCompanionBuilder
    = ChatRoomPreviewsCompanion Function({
  required String chatRoomId,
  required String lastMessageText,
  required String lastMessageId,
  required int updatedAt,
  Value<int> rowid,
});
typedef $$ChatRoomPreviewsTableUpdateCompanionBuilder
    = ChatRoomPreviewsCompanion Function({
  Value<String> chatRoomId,
  Value<String> lastMessageText,
  Value<String> lastMessageId,
  Value<int> updatedAt,
  Value<int> rowid,
});

class $$ChatRoomPreviewsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ChatRoomPreviewsTable,
    ChatRoomPreview,
    $$ChatRoomPreviewsTableFilterComposer,
    $$ChatRoomPreviewsTableOrderingComposer,
    $$ChatRoomPreviewsTableCreateCompanionBuilder,
    $$ChatRoomPreviewsTableUpdateCompanionBuilder> {
  $$ChatRoomPreviewsTableTableManager(
      _$AppDatabase db, $ChatRoomPreviewsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$ChatRoomPreviewsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$ChatRoomPreviewsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> chatRoomId = const Value.absent(),
            Value<String> lastMessageText = const Value.absent(),
            Value<String> lastMessageId = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ChatRoomPreviewsCompanion(
            chatRoomId: chatRoomId,
            lastMessageText: lastMessageText,
            lastMessageId: lastMessageId,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String chatRoomId,
            required String lastMessageText,
            required String lastMessageId,
            required int updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ChatRoomPreviewsCompanion.insert(
            chatRoomId: chatRoomId,
            lastMessageText: lastMessageText,
            lastMessageId: lastMessageId,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
        ));
}

class $$ChatRoomPreviewsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $ChatRoomPreviewsTable> {
  $$ChatRoomPreviewsTableFilterComposer(super.$state);
  ColumnFilters<String> get chatRoomId => $state.composableBuilder(
      column: $state.table.chatRoomId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get lastMessageText => $state.composableBuilder(
      column: $state.table.lastMessageText,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get lastMessageId => $state.composableBuilder(
      column: $state.table.lastMessageId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$ChatRoomPreviewsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $ChatRoomPreviewsTable> {
  $$ChatRoomPreviewsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get chatRoomId => $state.composableBuilder(
      column: $state.table.chatRoomId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get lastMessageText => $state.composableBuilder(
      column: $state.table.lastMessageText,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get lastMessageId => $state.composableBuilder(
      column: $state.table.lastMessageId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$LocalMessagesTableCreateCompanionBuilder = LocalMessagesCompanion
    Function({
  required String id,
  required String chatRoomId,
  required String messageJson,
  required int timestamp,
  Value<int> rowid,
});
typedef $$LocalMessagesTableUpdateCompanionBuilder = LocalMessagesCompanion
    Function({
  Value<String> id,
  Value<String> chatRoomId,
  Value<String> messageJson,
  Value<int> timestamp,
  Value<int> rowid,
});

class $$LocalMessagesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalMessagesTable,
    LocalMessage,
    $$LocalMessagesTableFilterComposer,
    $$LocalMessagesTableOrderingComposer,
    $$LocalMessagesTableCreateCompanionBuilder,
    $$LocalMessagesTableUpdateCompanionBuilder> {
  $$LocalMessagesTableTableManager(_$AppDatabase db, $LocalMessagesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$LocalMessagesTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$LocalMessagesTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> chatRoomId = const Value.absent(),
            Value<String> messageJson = const Value.absent(),
            Value<int> timestamp = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalMessagesCompanion(
            id: id,
            chatRoomId: chatRoomId,
            messageJson: messageJson,
            timestamp: timestamp,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String chatRoomId,
            required String messageJson,
            required int timestamp,
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalMessagesCompanion.insert(
            id: id,
            chatRoomId: chatRoomId,
            messageJson: messageJson,
            timestamp: timestamp,
            rowid: rowid,
          ),
        ));
}

class $$LocalMessagesTableFilterComposer
    extends FilterComposer<_$AppDatabase, $LocalMessagesTable> {
  $$LocalMessagesTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get chatRoomId => $state.composableBuilder(
      column: $state.table.chatRoomId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get messageJson => $state.composableBuilder(
      column: $state.table.messageJson,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get timestamp => $state.composableBuilder(
      column: $state.table.timestamp,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$LocalMessagesTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $LocalMessagesTable> {
  $$LocalMessagesTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get chatRoomId => $state.composableBuilder(
      column: $state.table.chatRoomId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get messageJson => $state.composableBuilder(
      column: $state.table.messageJson,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get timestamp => $state.composableBuilder(
      column: $state.table.timestamp,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MessagePlaintextsTableTableManager get messagePlaintexts =>
      $$MessagePlaintextsTableTableManager(_db, _db.messagePlaintexts);
  $$ChatRoomPreviewsTableTableManager get chatRoomPreviews =>
      $$ChatRoomPreviewsTableTableManager(_db, _db.chatRoomPreviews);
  $$LocalMessagesTableTableManager get localMessages =>
      $$LocalMessagesTableTableManager(_db, _db.localMessages);
}
