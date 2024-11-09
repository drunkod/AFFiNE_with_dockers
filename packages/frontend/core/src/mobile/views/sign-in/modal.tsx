import { IconButton, Modal, SafeArea } from '@affine/component';
import { authAtom } from '@affine/core/components/atoms';
import { CloseIcon } from '@blocksuite/icons/rc';
import { cssVarV2 } from '@toeverything/theme/v2';
import { useAtom } from 'jotai';
import { useCallback } from 'react';

import { MobileSignIn } from './mobile-sign-in';

export const MobileSignInModal = () => {
  const [authAtomValue, setAuthAtom] = useAtom(authAtom);
  const setOpen = useCallback(
    (open: boolean) => {
      setAuthAtom(prev => ({ ...prev, openModal: open }));
    },
    [setAuthAtom]
  );

  const closeModal = useCallback(() => {
    setOpen(false);
  }, [setOpen]);

  return (
    <Modal
      fullScreen
      animation="slideBottom"
      open={authAtomValue.openModal}
      onOpenChange={setOpen}
      contentOptions={{
        style: {
          padding: 0,
          overflowY: 'auto',
          backgroundColor: cssVarV2('layer/background/secondary'),
        },
      }}
      withoutCloseButton
    >
      <MobileSignIn onSkip={closeModal} />
      <SafeArea
        top
        style={{ position: 'absolute', top: 0, right: 0, paddingRight: 16 }}
        topOffset={8}
      >
        <IconButton
          size="24"
          variant="solid"
          icon={<CloseIcon />}
          style={{ borderRadius: 8, padding: 4 }}
          onClick={closeModal}
        />
      </SafeArea>
    </Modal>
  );
};
