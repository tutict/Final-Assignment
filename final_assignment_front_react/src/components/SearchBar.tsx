interface SearchBarProps {
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
  actions?: React.ReactNode;
}

export default function SearchBar({ value, onChange, placeholder, actions }: SearchBarProps) {
  return (
    <div className="search-bar">
      <input
        type="text"
        value={value}
        onChange={(event) => onChange(event.target.value)}
        placeholder={placeholder || '搜索...'}
      />
      <div className="search-actions">{actions}</div>
    </div>
  );
}
