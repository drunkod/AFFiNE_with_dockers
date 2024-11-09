import { useGlobalEvent } from '@affine/core/mobile/hooks/use-global-events';
import type { DocMeta } from '@blocksuite/affine/store';
import { useCallback, useState } from 'react';

import { DocCard } from '../../../components';
import * as styles from './masonry.css';

const calcColumnCount = () => {
  const maxCardWidth = 220;
  const windowWidth = window.innerWidth;
  const newColumnCount = Math.floor(
    (windowWidth - styles.paddingX * 2 - styles.columnGap) / maxCardWidth
  );
  return Math.max(newColumnCount, 2);
};

export const MasonryDocs = ({
  items,
  showTags,
}: {
  items: DocMeta[];
  showTags?: boolean;
}) => {
  const [columnCount, setColumnCount] = useState(calcColumnCount);

  const updateColumnCount = useCallback(() => {
    setColumnCount(calcColumnCount());
  }, []);
  useGlobalEvent('resize', updateColumnCount);

  return (
    <div className={styles.masonry} style={{ columnCount }}>
      {items.map(item => (
        <DocCard
          key={item.id}
          className={styles.masonryItem}
          showTags={showTags}
          meta={item}
          autoHeightById
        />
      ))}
    </div>
  );
};
