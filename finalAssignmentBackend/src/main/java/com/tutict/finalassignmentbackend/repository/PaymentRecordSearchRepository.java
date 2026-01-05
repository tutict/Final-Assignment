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

    @Query("""
    {
      "match_phrase_prefix": {
        "paymentNumber": {
          "query": "?0"
        }
      }
    }
    """)
    SearchHits<PaymentRecordDocument> searchByPaymentNumber(String paymentNumber, Pageable pageable);

    default SearchHits<PaymentRecordDocument> searchByPaymentNumber(String paymentNumber) {
        return searchByPaymentNumber(paymentNumber, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
    {
      "match_phrase_prefix": {
        "payerName": {
          "query": "?0"
        }
      }
    }
    """)
    SearchHits<PaymentRecordDocument> searchByPayerName(String payerName, Pageable pageable);

    default SearchHits<PaymentRecordDocument> searchByPayerName(String payerName) {
        return searchByPayerName(payerName, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
    {
      "term": {
        "paymentMethod.keyword": {
          "value": "?0"
        }
      }
    }
    """)
    SearchHits<PaymentRecordDocument> searchByPaymentMethod(String paymentMethod, Pageable pageable);

    default SearchHits<PaymentRecordDocument> searchByPaymentMethod(String paymentMethod) {
        return searchByPaymentMethod(paymentMethod, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
    {
      "term": {
        "paymentChannel.keyword": {
          "value": "?0"
        }
      }
    }
    """)
    SearchHits<PaymentRecordDocument> searchByPaymentChannel(String paymentChannel, Pageable pageable);

    default SearchHits<PaymentRecordDocument> searchByPaymentChannel(String paymentChannel) {
        return searchByPaymentChannel(paymentChannel, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }

    @Query("""
    {
      "range": {
        "paymentTime": {
          "gte": "?0",
          "lte": "?1"
        }
      }
    }
    """)
    SearchHits<PaymentRecordDocument> searchByPaymentTimeRange(String startTime, String endTime, Pageable pageable);

    default SearchHits<PaymentRecordDocument> searchByPaymentTimeRange(String startTime, String endTime) {
        return searchByPaymentTimeRange(startTime, endTime, PageRequest.of(0, DEFAULT_PAGE_SIZE));
    }
}
