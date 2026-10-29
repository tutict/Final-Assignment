package guardrail

import "testing"

func TestSanitize(t *testing.T) {
	tests := []struct {
		name  string
		input string
		want  string
	}{
		{
			name:  "removes context tags",
			input: "<retrieved_context>罚款应在15日内缴纳。[1]</retrieved_context>",
			want:  "罚款应在15日内缴纳。[1]",
		},
		{
			name:  "keeps leading connective when stripping label",
			input: "根据 retrieved_context，罚款应在15日内缴纳。[1]",
			want:  "根据 罚款应在15日内缴纳。[1]",
		},
		{
			name:  "removes trailing label but keeps citation",
			input: "罚款应在15日内缴纳。retrieved_context [3] 另见规定。",
			want:  "罚款应在15日内缴纳。[3] 另见规定。",
		},
		{
			name:  "removes manual document label",
			input: "manual_rag_document [doc-1] 的说明如下。",
			want:  "的说明如下。",
		},
		{
			name:  "removes rag chunk label",
			input: "rag_chunk_manual_1 [chunk] 的规定如下。",
			want:  "的规定如下。",
		},
		{
			name:  "removes placeholder citation",
			input: "罚款应在15日内缴纳。[ n ]",
			want:  "罚款应在15日内缴纳。",
		},
		{
			name:  "collapses repeated spaces",
			input: "罚款   应在15日内缴纳。",
			want:  "罚款 应在15日内缴纳。",
		},
		{
			name:  "removes space before punctuation",
			input: "罚款应在15日内缴纳 。",
			want:  "罚款应在15日内缴纳。",
		},
		{
			name:  "keeps ordinary answer untouched",
			input: "罚款应在15日内缴纳。[1][2]",
			want:  "罚款应在15日内缴纳。[1][2]",
		},
		{
			name:  "empty stays empty",
			input: "",
			want:  "",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := Sanitize(tt.input); got != tt.want {
				t.Fatalf("Sanitize(%q) = %q, want %q", tt.input, got, tt.want)
			}
		})
	}
}
