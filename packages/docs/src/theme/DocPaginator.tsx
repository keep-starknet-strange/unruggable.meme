import OriginalDocPaginator from '@theme-original/DocPaginator'
import React from 'react'
import styled from 'styled-components'

import SentimentTracking from '../components/SentimentTracking'
import { DocsSentimentSection } from '../utils/analyticsEvents'

const SentimentTrackingContainer = styled.div`
  margin-top: 1.5rem;
`

// eslint-disable-next-line import/no-unused-modules
export default function DocPaginator(props: React.PropsWithChildren) {
  return (
    <>
      <SentimentTrackingContainer>
        <SentimentTracking analyticsSection={DocsSentimentSection.BOTTOM_SECTION} />
      </SentimentTrackingContainer>
      <OriginalDocPaginator {...props} />
    </>
  )
}
