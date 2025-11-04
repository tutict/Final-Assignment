package com.tutict.finalassignmentbackend.repository;

import com.tutict.finalassignmentbackend.entity.elastic.PaymentRecordDocument;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.elasticsearch.annotations.Query;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface PaymentRecordSearchRepository extends ElasticsearchRepository<PaymentRecordDocument, Long> {

    int DEFAULT_PAGE_SIZE = 10;

    @Query("""
    {
      "term": {
        "fineId": {
          "value": ?0
        }
      }
    }
    """)
    SearchHits<PaymentRecordDocument> findByFineId(Long fineId, Pageable pageable);

    default SearchHits<PaymentRecordDocument> findByFineId(Long fineId) {
        return findByFineId(fineId, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
    {
      "match_phrase_prefix": {
        "payerIdCard": {
          "query": "?0"
        }
      }
    }
    """)
    SearchHits<PaymentRecordDocument> searchByPayerIdCard(String payerIdCard, Pageable pageable);

    default SearchHits<PaymentRecordDocument> searchByPayerIdCard(String payerIdCard) {
        return searchByPayerIdCard(payerIdCard, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
    {
      "match_phrase_prefix": {
        "paymentStatus": {
          "query": "?0"
        }
      }
    }
    """)
    SearchHits<PaymentRecordDocument> searchByPaymentStatus(String paymentStatus, Pageable pageable);

    default SearchHits<PaymentRecordDocument> searchByPaymentStatus(String paymentStatus) {
        return searchByPaymentStatus(paymentStatus, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
    {
      "match": {
        "transactionId": {
          "query": "?0",
          "fuzziness": "AUTO"
        }
      }
    }
    """)
    SearchHits<PaymentRecordDocument> searchByTransactionId(String transactionId, Pageable pageable);

    default SearchHits<PaymentRecordDocument> searchByTransactionId(String transactionId) {
        return searchByTransactionId(transactionId, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }
}
