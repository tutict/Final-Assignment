import PageLayout from '../../components/PageLayout';

export interface NewsSection {
  heading: string;
  content: string;
}

interface NewsPageProps {
  title: string;
  sections: NewsSection[];
}

export default function NewsPage({ title, sections }: NewsPageProps) {
  return (
    <PageLayout title={title} subtitle="交通安全资讯与快速指南">
      <div className="news-layout">
        {sections.map((section) => (
          <div key={section.heading} className="news-card">
            <h3>{section.heading}</h3>
            <p>{section.content}</p>
          </div>
        ))}
      </div>
    </PageLayout>
  );
}
