import pyperclip
import os
import shutil
import nltk

# 必要なデータをダウンロード
nltk.download('punkt')

def split_text_into_sentences(text):
    sentences = nltk.sent_tokenize(text)
    return sentences

def split_sentences_into_chunks(sentences, words_per_chunk=400):
    chunks = []
    current_chunk = []
    current_word_count = 0

    for sentence in sentences:
        words_in_sentence = len(sentence.split())
        if current_word_count + words_in_sentence <= words_per_chunk or not current_chunk:
            current_chunk.append(sentence)
            current_word_count += words_in_sentence
        else:
            chunks.append(' '.join(current_chunk))
            current_chunk = [sentence]
            current_word_count = words_in_sentence

    if current_chunk:
        chunks.append(' '.join(current_chunk))
        
    return chunks

def remove_empty_lines(text):
    lines = text.split('\n')
    non_empty_lines = [line.strip() for line in lines if line.strip()]
    return ' '.join(non_empty_lines)

def clear_output_directory(output_dir):
    if os.path.exists(output_dir):
        shutil.rmtree(output_dir)
    os.makedirs(output_dir)

def save_chunks_to_files(chunks, output_dir):
    clear_output_directory(output_dir)
    
    for i, chunk in enumerate(chunks):
        with open(os.path.join(output_dir, f"output_{i+1}.txt"), 'w', encoding='utf-8') as file:
            file.write(chunk)

def main():
    # 出力ディレクトリの指定
    output_dir = "/Users/zak/ghq/github.com/1206yaya/anki/output"
    
    # クリップボードからテキストを取得
    clipboard_text = pyperclip.paste()
    
    # 空行を削除
    cleaned_text = remove_empty_lines(clipboard_text)
    
    # テキストを文章に分割
    sentences = split_text_into_sentences(cleaned_text)
    
    # 約75単語ごとに分割
    text_chunks = split_sentences_into_chunks(sentences)
    
    # ファイルに分割したテキストを保存
    save_chunks_to_files(text_chunks, output_dir)

if __name__ == "__main__":
    main()
