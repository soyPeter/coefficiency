import { useIntl } from 'react-intl';
import { Helmet } from 'react-helmet-async';
import { LayoutProvider } from './components/context';
import { Main } from './components/main';

export function Layout1() {
  const intl = useIntl();
  return (
    <>
      <Helmet>
        <title>{intl.formatMessage({ id: 'app.title' })}</title>
      </Helmet>
      <LayoutProvider>
        <Main />
      </LayoutProvider>
    </>
  );
}
