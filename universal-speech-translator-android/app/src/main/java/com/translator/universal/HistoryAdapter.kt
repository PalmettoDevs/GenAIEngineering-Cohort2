package com.translator.universal

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.ListAdapter
import androidx.recyclerview.widget.RecyclerView
import com.translator.universal.databinding.ItemHistoryBinding

data class HistoryItem(
    val original: String,
    val translated: String,
    val sourceLang: String,
    val targetLang: String,
    val timestamp: Long = System.currentTimeMillis()
)

class HistoryAdapter(
    private val onItemClick: (HistoryItem) -> Unit
) : ListAdapter<HistoryItem, HistoryAdapter.ViewHolder>(DIFF_CALLBACK) {

    class ViewHolder(
        val binding: ItemHistoryBinding
    ) : RecyclerView.ViewHolder(binding.root)

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val binding = ItemHistoryBinding.inflate(
            LayoutInflater.from(parent.context), parent, false
        )
        return ViewHolder(binding)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val item = getItem(position)
        holder.binding.apply {
            originalText.text = item.original
            translatedText.text = item.translated

            val srcName = LanguageRepository.findByCode(item.sourceLang)?.displayName ?: item.sourceLang
            val tgtName = LanguageRepository.findByCode(item.targetLang)?.displayName ?: item.targetLang
            languagePairLabel.text = "$srcName → $tgtName"

            root.setOnClickListener { onItemClick(item) }
        }
    }

    companion object {
        private val DIFF_CALLBACK = object : DiffUtil.ItemCallback<HistoryItem>() {
            override fun areItemsTheSame(old: HistoryItem, new: HistoryItem) =
                old.timestamp == new.timestamp
            override fun areContentsTheSame(old: HistoryItem, new: HistoryItem) =
                old == new
        }
    }
}
